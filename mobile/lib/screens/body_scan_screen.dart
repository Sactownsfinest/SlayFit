import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/measurements_provider.dart';
import '../providers/user_provider.dart';

class BodyScanScreen extends ConsumerStatefulWidget {
  const BodyScanScreen({super.key});

  @override
  ConsumerState<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends ConsumerState<BodyScanScreen> {
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  final _armsCtrl = TextEditingController();
  final _thighsCtrl = TextEditingController();
  bool _saving = false;

  bool get _useMetric => ref.read(userProfileProvider).useMetric;

  @override
  void dispose() {
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _armsCtrl.dispose();
    _thighsCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    if (v == null || v <= 0) return null;
    // Convert inches to cm if imperial
    return _useMetric ? v : v * 2.54;
  }

  bool get _hasAny =>
      _parse(_chestCtrl) != null ||
      _parse(_waistCtrl) != null ||
      _parse(_hipsCtrl) != null ||
      _parse(_armsCtrl) != null ||
      _parse(_thighsCtrl) != null;

  Future<void> _save() async {
    if (!_hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement')),
      );
      return;
    }
    setState(() => _saving = true);
    final entry = BodyMeasurement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      chestCm: _parse(_chestCtrl),
      waistCm: _parse(_waistCtrl),
      hipsCm: _parse(_hipsCtrl),
      armsCm: _parse(_armsCtrl),
      thighsCm: _parse(_thighsCtrl),
    );
    await ref.read(measurementsProvider.notifier).addMeasurement(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _useMetric ? 'cm' : 'in';
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        title: const Text('Log Measurements'),
        backgroundColor: kPrimaryDark,
        foregroundColor: kTextPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tip card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: kNeonYellow, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use a soft tape measure. Measure around the widest/narrowest point. '
                      'Enter values in $unit — leave blank to skip.',
                      style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _MeasurementField(
              label: 'Chest',
              unit: unit,
              controller: _chestCtrl,
              hint: _useMetric ? 'e.g. 95' : 'e.g. 37.5',
              icon: Icons.accessibility_new,
            ),
            const SizedBox(height: 14),
            _MeasurementField(
              label: 'Waist',
              unit: unit,
              controller: _waistCtrl,
              hint: _useMetric ? 'e.g. 80' : 'e.g. 31.5',
              icon: Icons.straighten,
            ),
            const SizedBox(height: 14),
            _MeasurementField(
              label: 'Hips',
              unit: unit,
              controller: _hipsCtrl,
              hint: _useMetric ? 'e.g. 95' : 'e.g. 37.5',
              icon: Icons.airline_seat_legroom_normal,
            ),
            const SizedBox(height: 14),
            _MeasurementField(
              label: 'Arms (each)',
              unit: unit,
              controller: _armsCtrl,
              hint: _useMetric ? 'e.g. 33' : 'e.g. 13',
              icon: Icons.fitness_center,
            ),
            const SizedBox(height: 14),
            _MeasurementField(
              label: 'Thighs (each)',
              unit: unit,
              controller: _thighsCtrl,
              hint: _useMetric ? 'e.g. 55' : 'e.g. 21.5',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Save Measurements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final String label;
  final String unit;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _MeasurementField({
    required this.label,
    required this.unit,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kNeonYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kNeonYellow, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixText: unit,
              suffixStyle:
                  const TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
