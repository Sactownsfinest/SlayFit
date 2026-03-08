import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../data/guided_classes.dart';
import '../main.dart';

// ── Entry point: class preview/start screen ───────────────────────────────────

class GuidedClassStartScreen extends StatelessWidget {
  final GuidedClass guidedClass;
  const GuidedClassStartScreen({super.key, required this.guidedClass});

  @override
  Widget build(BuildContext context) {
    final c = guidedClass;
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kTextSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(c.icon, color: c.color, size: 40),
                    const SizedBox(height: 16),
                    Text(c.title,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(c.subtitle,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats row
              Row(
                children: [
                  _StatChip(Icons.timer_outlined, '${c.totalMinutes} min'),
                  const SizedBox(width: 10),
                  _StatChip(Icons.bar_chart, c.difficulty),
                  const SizedBox(width: 10),
                  _StatChip(Icons.self_improvement, c.category),
                ],
              ),
              const SizedBox(height: 28),
              // Step list preview
              Text('What\'s in this class',
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: c.steps.length,
                  itemBuilder: (_, i) {
                    final step = c.steps[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      color: c.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(step.name,
                                style: const TextStyle(
                                    color: kTextPrimary, fontSize: 13)),
                          ),
                          Text(
                            '${step.durationSeconds}s',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Audio notice
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kNeonYellow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: kNeonYellow.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.volume_up, color: kNeonYellow, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Plug in headphones for the best experience',
                        style:
                            TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GuidedClassPlayerScreen(guidedClass: c),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Let's Go",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kTextSecondary, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Player screen ─────────────────────────────────────────────────────────────

class GuidedClassPlayerScreen extends StatefulWidget {
  final GuidedClass guidedClass;
  const GuidedClassPlayerScreen({super.key, required this.guidedClass});

  @override
  State<GuidedClassPlayerScreen> createState() =>
      _GuidedClassPlayerScreenState();
}

class _GuidedClassPlayerScreenState extends State<GuidedClassPlayerScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();

  int _stepIndex = 0;
  int _secondsLeft = 0;
  bool _isPlaying = false;
  bool _isComplete = false;

  Timer? _timer;

  // Pulse animation for the timer ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Track which cues have been played per step
  bool _cuePlayed = false;
  bool _endCuePlayed = false;

  GuidedClass get _class => widget.guidedClass;
  GuidedClassStep get _currentStep => _class.steps[_stepIndex];

  int get _totalSeconds => _class.totalSeconds;
  int get _elapsedSeconds {
    int e = 0;
    for (int i = 0; i < _stepIndex; i++) {
      e += _class.steps[i].durationSeconds;
    }
    e += (_currentStep.durationSeconds - _secondsLeft);
    return e;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startClass();
  }

  Future<void> _startClass() async {
    await _playAudio(_class.audioIntro);
    if (mounted) _beginStep(0);
  }

  void _beginStep(int index) {
    _timer?.cancel();
    setState(() {
      _stepIndex = index;
      _secondsLeft = _class.steps[index].durationSeconds;
      _isPlaying = true;
      _cuePlayed = false;
      _endCuePlayed = false;
    });
    _playAudio(_class.steps[index].audioStart);
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (!_isPlaying) return;
    setState(() => _secondsLeft--);

    final step = _currentStep;
    final mid = step.durationSeconds ~/ 2;

    // Mid-point cue
    if (!_cuePlayed && _secondsLeft <= mid && step.audioCue != null) {
      _cuePlayed = true;
      _playAudio(step.audioCue!);
    }
    // 10-second warning cue
    if (!_endCuePlayed && _secondsLeft == 10 && step.durationSeconds > 20) {
      _endCuePlayed = true;
      _playAudio(step.audioEnd);
    }
    // Step done
    if (_secondsLeft <= 0) {
      t.cancel();
      _advanceStep();
    }
  }

  void _advanceStep() {
    if (_stepIndex >= _class.steps.length - 1) {
      _completeClass();
    } else {
      _beginStep(_stepIndex + 1);
    }
  }

  Future<void> _completeClass() async {
    setState(() {
      _isPlaying = false;
      _isComplete = true;
    });
    await _playAudio(_class.audioOutro);
  }

  Future<void> _playAudio(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Audio file not yet added — silently skip
    }
  }

  void _togglePause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _player.resume();
    } else {
      _player.pause();
    }
  }

  void _skipForward() {
    if (_stepIndex < _class.steps.length - 1) {
      _timer?.cancel();
      _beginStep(_stepIndex + 1);
    }
  }

  void _skipBack() {
    _timer?.cancel();
    if (_secondsLeft < _currentStep.durationSeconds - 3 || _stepIndex == 0) {
      // Restart current step
      _beginStep(_stepIndex);
    } else {
      _beginStep(max(0, _stepIndex - 1));
    }
  }

  Future<bool> _onWillPop() async {
    if (_isComplete) return true;
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave class?',
            style: TextStyle(color: kTextPrimary)),
        content: const Text('Your progress will not be saved.',
            style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay',
                style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isComplete,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _onWillPop()) nav.pop();
      },
      child: Scaffold(
        backgroundColor: kPrimaryDark,
        body: _isComplete ? _buildCompleteScreen() : _buildPlayerScreen(),
      ),
    );
  }

  Widget _buildPlayerScreen() {
    final step = _currentStep;
    final classColor = _class.color;
    final overallProgress = _elapsedSeconds / _totalSeconds;
    final stepProgress = 1.0 -
        (_secondsLeft / step.durationSeconds).clamp(0.0, 1.0);

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await _onWillPop()) nav.pop();
                  },
                ),
                Expanded(
                  child: Text(
                    _class.title,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_stepIndex + 1} / ${_class.steps.length}',
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // Overall progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: kCardDark,
                color: classColor,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Step name + description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  step.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: classColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Circular timer
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: _isPlaying ? _pulseAnim.value : 1.0,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: stepProgress,
                        strokeWidth: 10,
                        backgroundColor: kCardDark,
                        color: classColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_secondsLeft),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          _isPlaying ? 'remaining' : 'paused',
                          style: TextStyle(
                            color: _isPlaying
                                ? kTextSecondary
                                : Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Instructions card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3550)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Form Tips',
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    ...step.instructions.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle,
                                  color: classColor, size: 6),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(tip,
                                    style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip back
                IconButton(
                  onPressed: _skipBack,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: kTextSecondary, size: 32),
                ),
                // Pause / Play
                GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: classColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: classColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
                // Skip forward
                IconButton(
                  onPressed:
                      _stepIndex < _class.steps.length - 1
                          ? _skipForward
                          : null,
                  icon: Icon(Icons.skip_next_rounded,
                      color: _stepIndex < _class.steps.length - 1
                          ? kTextSecondary
                          : const Color(0xFF2A3550),
                      size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _class.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_class.icon, color: _class.color, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Class Complete!',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
              const SizedBox(height: 8),
              Text(_class.title,
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 15)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CompleteStat(
                      '${_class.totalMinutes}',
                      'minutes',
                      _class.color),
                  _CompleteStat(
                      '${_class.steps.length}',
                      'exercises',
                      _class.color),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _class.color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0
        ? '$m:${s.toString().padLeft(2, '0')}'
        : s.toString();
  }
}

class _CompleteStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _CompleteStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 36)),
        Text(label,
            style:
                const TextStyle(color: kTextSecondary, fontSize: 13)),
      ],
    );
  }
}
