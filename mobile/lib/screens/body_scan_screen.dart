import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../providers/measurements_provider.dart';
import '../providers/user_provider.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────

enum _ScanStep { frontGuide, processing, sideGuide, results }

// ── Data passed to background isolate ────────────────────────────────────────

class _IsolateInput {
  final Uint8List pixels;
  final int width;
  final int height;
  final double heightCm;
  const _IsolateInput(this.pixels, this.width, this.height, this.heightCm);
}

class _StepData {
  final double scale; // pixels per cm
  final double hipWidthPx;
  final double waistWidthPx;
  final double chestWidthPx;
  const _StepData({
    required this.scale,
    required this.hipWidthPx,
    required this.waistWidthPx,
    required this.chestWidthPx,
  });
}

class _FinalMeasurements {
  final double hipsCm;
  final double waistCm;
  final double chestCm;
  const _FinalMeasurements({
    required this.hipsCm,
    required this.waistCm,
    required this.chestCm,
  });
}

// ── Pixel scanning (runs in compute isolate) ──────────────────────────────────

_StepData? _scanPixels(_IsolateInput input) {
  final pixels = input.pixels;
  final w = input.width;
  final h = input.height;

  if (w == 0 || h == 0) return null;

  // Sample background from 4 corners (10x10 blocks each)
  int bgR = 0, bgG = 0, bgB = 0, bgCount = 0;
  const sample = 10;
  final cornerOffsets = [
    [0, 0],
    [w - sample, 0],
    [0, h - sample],
    [w - sample, h - sample],
  ];
  for (final c in cornerOffsets) {
    final cx = c[0], cy = c[1];
    for (int dy = 0; dy < sample; dy++) {
      for (int dx = 0; dx < sample; dx++) {
        final x = cx + dx, y = cy + dy;
        if (x >= 0 && x < w && y >= 0 && y < h) {
          final idx = (y * w + x) * 4;
          bgR += pixels[idx];
          bgG += pixels[idx + 1];
          bgB += pixels[idx + 2];
          bgCount++;
        }
      }
    }
  }
  if (bgCount == 0) return null;
  bgR ~/= bgCount;
  bgG ~/= bgCount;
  bgB ~/= bgCount;

  // Determine foreground threshold — adaptive based on bg brightness
  final bgBrightness = (bgR + bgG + bgB) ~/ 3;
  final threshold = bgBrightness > 128 ? 35 : 45;

  bool isFg(int x, int y) {
    final idx = (y * w + x) * 4;
    return ((pixels[idx] - bgR).abs() +
            (pixels[idx + 1] - bgG).abs() +
            (pixels[idx + 2] - bgB).abs()) >
        threshold;
  }

  // Detect body vertical extent (search center 60% of image width)
  final xMin = (w * 0.20).round();
  final xMax = (w * 0.80).round();

  int bodyTop = -1, bodyBottom = -1;
  for (int y = 0; y < h; y++) {
    for (int x = xMin; x < xMax; x++) {
      if (isFg(x, y)) {
        if (bodyTop == -1) bodyTop = y;
        bodyBottom = y;
        break;
      }
    }
  }
  if (bodyTop < 0 || bodyBottom < 0) return null;

  final bodyH = (bodyBottom - bodyTop).clamp(1, h);
  // scale: px per cm (full height top-of-head to floor)
  final scale = bodyH / input.heightCm;

  // Measure body width at a given y: find leftmost & rightmost foreground px
  int rowWidth(int y) {
    int left = -1, right = -1;
    for (int x = 0; x < w; x++) {
      if (isFg(x, y)) {
        if (left == -1) left = x;
        right = x;
      }
    }
    return (left < 0) ? 0 : right - left;
  }

  // Key body zones (as fraction of bodyH from bodyTop)
  final shoulderY = bodyTop + (bodyH * 0.22).round();
  final hipJointY = bodyTop + (bodyH * 0.52).round();

  // Hips: find max width from hip joint down to 65% of body
  int hipW = 0;
  final hipEnd = bodyTop + (bodyH * 0.65).round();
  for (int y = hipJointY; y <= hipEnd && y < h; y++) {
    final rw = rowWidth(y);
    if (rw > hipW) hipW = rw;
  }

  // Waist: find min width in middle third between shoulder and hip joint
  int waistW = 0x7FFFFFFF;
  final wStart = shoulderY + ((hipJointY - shoulderY) * 0.3).round();
  final wEnd = shoulderY + ((hipJointY - shoulderY) * 0.7).round();
  for (int y = wStart; y <= wEnd && y < h; y++) {
    final rw = rowWidth(y);
    if (rw > 0 && rw < waistW) waistW = rw;
  }
  if (waistW == 0x7FFFFFFF) waistW = rowWidth((shoulderY + hipJointY) ~/ 2);

  // Chest: max width 10–25% below shoulder toward hip
  int chestW = 0;
  final cStart = shoulderY + ((hipJointY - shoulderY) * 0.10).round();
  final cEnd = shoulderY + ((hipJointY - shoulderY) * 0.25).round();
  for (int y = cStart; y <= cEnd && y < h; y++) {
    final rw = rowWidth(y);
    if (rw > chestW) chestW = rw;
  }

  return _StepData(
    scale: scale,
    hipWidthPx: hipW.toDouble(),
    waistWidthPx: waistW.toDouble(),
    chestWidthPx: chestW.toDouble(),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BodyScanScreen extends ConsumerStatefulWidget {
  const BodyScanScreen({super.key});

  @override
  ConsumerState<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends ConsumerState<BodyScanScreen> {
  final _picker = ImagePicker();

  _ScanStep _step = _ScanStep.frontGuide;
  String? _error;
  _StepData? _frontData;
  _FinalMeasurements? _final;

  // Load image with EXIF correction via Flutter's image pipeline
  Future<ui.Image> _loadImage(String path) async {
    final provider = FileImage(File(path));
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        completer.complete(info.image.clone());
        stream.removeListener(listener);
      },
      onError: (e, st) {
        completer.completeError(e, st);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _capture({required bool isFront}) async {
    setState(() {
      _step = _ScanStep.processing;
      _error = null;
    });

    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (xfile == null) {
        // User cancelled
        setState(() =>
            _step = isFront ? _ScanStep.frontGuide : _ScanStep.sideGuide);
        return;
      }

      // Decode with EXIF handling
      final uiImg = await _loadImage(xfile.path);
      final byteData =
          await uiImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      uiImg.dispose();

      if (byteData == null) throw Exception('Could not decode image');

      final profile = ref.read(userProfileProvider);
      final heightCm = profile.heightCm.clamp(100.0, 250.0);

      // Process in background isolate (pure Dart, no Flutter APIs)
      final input = _IsolateInput(
        byteData.buffer.asUint8List(),
        uiImg.width,
        uiImg.height,
        heightCm,
      );
      final data = await compute(_scanPixels, input);

      // Clean up temp file
      try {
        File(xfile.path).deleteSync();
      } catch (_) {}

      if (data == null) {
        setState(() {
          _error =
              'Could not detect your body outline.\nTip: stand against a plain light-coloured wall in fitted clothing.';
          _step = isFront ? _ScanStep.frontGuide : _ScanStep.sideGuide;
        });
        return;
      }

      if (isFront) {
        setState(() {
          _frontData = data;
          _step = _ScanStep.sideGuide;
        });
      } else {
        final result = _computeFinal(_frontData!, data);
        setState(() {
          _final = result;
          _step = _ScanStep.results;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Scan failed — please try again.';
        _step = isFront ? _ScanStep.frontGuide : _ScanStep.sideGuide;
      });
    }
  }

  _FinalMeasurements _computeFinal(_StepData front, _StepData side) {
    final s = front.scale;

    // Convert pixel widths to cm
    final hipW = front.hipWidthPx / s;
    final hipD = side.hipWidthPx / s;
    final waistW = front.waistWidthPx / s;
    final waistD = side.waistWidthPx / s;
    final chestW = front.chestWidthPx / s;
    final chestD = side.chestWidthPx / s;

    // Ramanujan's ellipse: C ≈ π(a+b)(1 + 3h/(10+√(4−3h)))
    double ellipseCirc(double width, double depth) {
      final a = width / 2;
      final b = depth / 2;
      if (a <= 0 || b <= 0) return math.pi * math.max(a, b) * 2;
      final h = math.pow(a - b, 2) / math.pow(a + b, 2);
      final inner = (4.0 - 3.0 * h).clamp(0.0, 4.0);
      return math.pi * (a + b) * (1.0 + 3.0 * h / (10.0 + math.sqrt(inner)));
    }

    return _FinalMeasurements(
      hipsCm: ellipseCirc(hipW, hipD),
      waistCm: ellipseCirc(waistW, waistD),
      chestCm: ellipseCirc(chestW, chestD),
    );
  }

  Future<void> _save() async {
    final m = _final;
    if (m == null) return;
    final entry = BodyMeasurement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      waistCm: m.waistCm,
      hipsCm: m.hipsCm,
      chestCm: m.chestCm,
    );
    await ref.read(measurementsProvider.notifier).addMeasurement(entry);
    if (mounted) Navigator.pop(context);
  }

  void _rescan() => setState(() {
        _step = _ScanStep.frontGuide;
        _frontData = null;
        _final = null;
        _error = null;
      });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: SafeArea(
        child: switch (_step) {
          _ScanStep.frontGuide => _buildGuide(isFront: true),
          _ScanStep.sideGuide => _buildGuide(isFront: false),
          _ScanStep.processing => _buildProcessing(),
          _ScanStep.results => _buildResults(),
        },
      ),
    );
  }

  Widget _buildGuide({required bool isFront}) {
    final stepNum = isFront ? '1' : '2';
    final title = 'Step $stepNum of 2 — ${isFront ? 'Front' : 'Side'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: kTextSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepDot(filled: true),
            const SizedBox(width: 6),
            _StepDot(filled: !isFront),
          ],
        ),

        const SizedBox(height: 20),

        // Silhouette preview
        Expanded(
          child: Center(
            child: CustomPaint(
              size: const Size(180, 340),
              painter: _SilhouettePainter(isFront: isFront),
            ),
          ),
        ),

        // Error banner
        if (_error != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center),
          ),

        // Instructions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFront ? 'Front photo tips:' : 'Side photo tips:',
                style: const TextStyle(
                    color: kNeonYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...(isFront
                      ? [
                          'Stand 2–3 m from the phone',
                          'Face the camera, full body in frame',
                          'Arms slightly away from sides',
                          'Plain light-coloured wall behind you',
                          'Wear fitted clothes or swimwear',
                        ]
                      : [
                          'Turn 90° to your right',
                          'Full body in frame, stand straight',
                          'Keep arm slightly forward',
                          'Same plain background as front photo',
                        ])
                  .map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: kTextSecondary, fontSize: 13)),
                            Expanded(
                              child: Text(tip,
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 13)),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Capture button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: () => _capture(isFront: isFront),
            icon: const Icon(Icons.camera_alt, color: Colors.black),
            label: Text(
              isFront ? 'Take Front Photo' : 'Take Side Photo',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonYellow,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: kNeonYellow),
          SizedBox(height: 20),
          Text('Analysing photo…',
              style: TextStyle(color: kTextSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final m = _final!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: kNeonYellow),
                onPressed: _rescan,
                tooltip: 'Rescan',
              ),
              const Expanded(
                child: Text('Scan Results',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: kTextSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            'Best accuracy: fitted clothing, plain light background, 2–3 m distance. '
            'Use for tracking trends, not clinical measurements.',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _ResultTile(label: 'Chest', value: m.chestCm),
              _ResultTile(label: 'Waist', value: m.waistCm),
              _ResultTile(label: 'Hips', value: m.hipsCm),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save to Measurements',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _rescan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  side: const BorderSide(color: Color(0xFF2A3550)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Scan Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool filled;
  const _StepDot({required this.filled});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: filled ? 28 : 10,
        height: 8,
        decoration: BoxDecoration(
          color: filled ? kNeonYellow : Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _ResultTile extends StatelessWidget {
  final String label;
  final double value;
  const _ResultTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: kCardDark, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: kTextPrimary, fontSize: 15)),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} cm',
              style: const TextStyle(
                  color: kNeonYellow,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text('(${(value / 2.54).toStringAsFixed(1)}")',
              style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Silhouette guide painter ──────────────────────────────────────────────────

class _SilhouettePainter extends CustomPainter {
  final bool isFront;
  const _SilhouettePainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kNeonYellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final top = size.height * 0.02;
    final bot = size.height * 0.98;
    final totalH = bot - top;

    final headR = totalH * 0.07;
    final headCy = top + headR;
    final shoulderY = headCy + headR * 1.2;
    final shoulderW = totalH * 0.20;
    final waistW = totalH * 0.13;
    final hipW = totalH * 0.19;
    final waistY = shoulderY + totalH * 0.22;
    final hipY = shoulderY + totalH * 0.33;
    final legW = totalH * 0.075;

    canvas.drawCircle(Offset(cx, headCy), headR, paint);

    if (isFront) {
      final body = Path()
        // Shoulders
        ..moveTo(cx - shoulderW, shoulderY)
        ..lineTo(cx + shoulderW, shoulderY)
        // Right side torso
        ..moveTo(cx + shoulderW, shoulderY)
        ..quadraticBezierTo(cx + waistW, waistY, cx + hipW, hipY)
        // Left side torso
        ..moveTo(cx - shoulderW, shoulderY)
        ..quadraticBezierTo(cx - waistW, waistY, cx - hipW, hipY)
        // Hip line
        ..moveTo(cx - hipW, hipY)
        ..lineTo(cx + hipW, hipY)
        // Right leg
        ..moveTo(cx + hipW, hipY)
        ..lineTo(cx + legW, bot)
        // Left leg
        ..moveTo(cx - hipW, hipY)
        ..lineTo(cx - legW, bot)
        // Right arm
        ..moveTo(cx + shoulderW, shoulderY)
        ..lineTo(cx + shoulderW + legW * 0.9, hipY * 0.88)
        // Left arm
        ..moveTo(cx - shoulderW, shoulderY)
        ..lineTo(cx - shoulderW - legW * 0.9, hipY * 0.88);
      canvas.drawPath(body, paint);
    } else {
      final sW = shoulderW * 0.38;
      final chestBulge = sW * 0.4;
      final side = Path()
        ..moveTo(cx - sW, shoulderY)
        ..lineTo(cx - sW, hipY)
        ..lineTo(cx - sW * 0.7, bot)
        ..moveTo(cx - sW, shoulderY)
        ..lineTo(cx + sW + chestBulge, shoulderY + totalH * 0.05)
        ..quadraticBezierTo(
            cx + sW * 0.5, waistY, cx + sW, hipY)
        ..lineTo(cx + sW * 0.7, bot);
      canvas.drawPath(side, paint);
    }

    // Faint centre line
    canvas.drawLine(
      Offset(cx, headCy + headR),
      Offset(cx, bot),
      Paint()
        ..color = Colors.white12
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.isFront != isFront;
}
