import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';
import '../services/cloud_sync_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _loading = false;

  String _name = '';
  String _sex = 'M';
  double _weight = 80;    // always kg internally
  double _height = 170;   // always cm internally
  double _goalWeight = 70; // always kg internally
  String _pace = 'steady';
  String _activityLevel = 'moderate';
  bool _useMetric = false; // default to imperial (lbs / ft·in)

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateCalorieGoal() {
    double bmr;
    if (_sex == 'M') {
      bmr = 10 * _weight + 6.25 * _height - 145;
    } else if (_sex == 'F') {
      bmr = 10 * _weight + 6.25 * _height - 311;
    } else {
      bmr = 10 * _weight + 6.25 * _height - 228;
    }
    const multipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderate': 1.55,
      'very_active': 1.725,
    };
    final tdee = bmr * (multipliers[_activityLevel] ?? 1.55);
    const deficits = {'slow': 275.0, 'steady': 550.0, 'aggressive': 1100.0};
    final deficit = deficits[_pace] ?? 550.0;
    return (tdee - deficit).round().clamp(1200, 3000);
  }

  Future<void> _completeOnboarding() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final calories = _calculateCalorieGoal();
      final trimmedName = _name.trim().isEmpty ? 'User' : _name.trim();
      // Save name to shared prefs so other providers pick it up
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', trimmedName);
      final profile = ref.read(userProfileProvider).copyWith(
            name: trimmedName,
            sex: _sex,
            heightCm: _height,
            goalWeightKg: _goalWeight,
            activityLevel: _activityLevel,
            dailyCalorieGoal: calories,
            useMetric: _useMetric,
          );
      await ref.read(userProfileProvider.notifier).update(profile);
      ref.read(weightProvider.notifier).logWeight(_weight);
      ref.read(foodLogProvider.notifier).setCalorieGoal(calories.toDouble());
      // Mark onboarding complete BEFORE uploadAll so Firestore gets the correct value
      await prefs.setBool('onboarding_completed', true);
      await CloudSyncService.uploadAll();
      ref.read(authProvider.notifier).completeOnboarding();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: PageView(
        controller: _pageController,
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _Page1(onNameChanged: (v) => setState(() => _name = v)),
          _Page2(
            sex: _sex,
            weight: _weight,
            height: _height,
            useMetric: _useMetric,
            onSexChanged: (v) => setState(() => _sex = v),
            onWeightChanged: (v) => setState(() => _weight = v),
            onHeightChanged: (v) => setState(() => _height = v),
            onUseMetricChanged: (v) => setState(() => _useMetric = v),
          ),
          _Page3(
            goalWeight: _goalWeight,
            pace: _pace,
            useMetric: _useMetric,
            onGoalWeightChanged: (v) => setState(() => _goalWeight = v),
            onPaceChanged: (v) => setState(() => _pace = v),
          ),
          _Page4(
            activityLevel: _activityLevel,
            onActivityChanged: (v) => setState(() => _activityLevel = v),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: kPrimaryDark,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  side: const BorderSide(color: Color(0xFF2A3550)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Back'),
              )
            else
              const SizedBox(width: 80),
            Row(
              children: List.generate(
                4,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 8,
                  width: _currentPage == i ? 24 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? kNeonYellow
                        : const Color(0xFF2A3550),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            if (_currentPage < 3)
              ElevatedButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Next',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              ElevatedButton(
                onPressed: _loading ? null : _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: kNeonYellow.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text("Let's Go!",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────
class _Page1 extends ConsumerStatefulWidget {
  final ValueChanged<String> onNameChanged;
  const _Page1({required this.onNameChanged});

  @override
  ConsumerState<_Page1> createState() => _Page1State();
}

class _Page1State extends ConsumerState<_Page1> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: kNeonYellow,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kNeonYellow.withValues(alpha: 0.75),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: kNeonYellow.withValues(alpha: 0.30),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, size: 52, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'SLAYFIT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'BY SHENNEL',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: kNeonYellow,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your intelligent weight loss companion.\nLet us set up your personalized plan.',
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: kTextPrimary),
              onChanged: widget.onNameChanged,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'What should we call you?',
                prefixIcon: Icon(Icons.person_outline, color: kTextSecondary),
              ),
            ),
            const SizedBox(height: 28),
            _FeatureRow(
                icon: Icons.restaurant_outlined,
                text: 'Track food & calories'),
            const SizedBox(height: 12),
            _FeatureRow(
                icon: Icons.fitness_center_outlined,
                text: 'Log workouts & activity'),
            const SizedBox(height: 12),
            _FeatureRow(
                icon: Icons.trending_down,
                text: 'Monitor your weight loss'),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
              child: const Text(
                'Already have an account? Sign in',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kNeonYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kNeonYellow, size: 22),
        ),
        const SizedBox(width: 16),
        Text(text,
            style: const TextStyle(color: kTextPrimary, fontSize: 15)),
      ],
    );
  }
}

// ─── Page 2: Body Stats ────────────────────────────────────────────────────────
class _Page2 extends StatelessWidget {
  final String sex;
  final double weight;   // always kg
  final double height;   // always cm
  final bool useMetric;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<double> onWeightChanged;   // receives kg
  final ValueChanged<double> onHeightChanged;   // receives cm
  final ValueChanged<bool> onUseMetricChanged;

  const _Page2({
    required this.sex,
    required this.weight,
    required this.height,
    required this.useMetric,
    required this.onSexChanged,
    required this.onWeightChanged,
    required this.onHeightChanged,
    required this.onUseMetricChanged,
  });

  String _fmtHeight(double cm) {
    final totalIn = (cm / 2.54).round();
    return "${totalIn ~/ 12}' ${totalIn % 12}\"";
  }

  @override
  Widget build(BuildContext context) {
    // Weight slider values in display unit
    final double wVal = useMetric ? weight : weight * 2.20462;
    final double wMin = useMetric ? 40.0 : 88.0;
    final double wMax = useMetric ? 200.0 : 441.0;
    final String wUnit = useMetric ? 'kg' : 'lbs';

    // Height slider in display unit (cm or total inches)
    final double hVal = useMetric ? height : height / 2.54;
    final double hMin = useMetric ? 140.0 : 55.0;
    final double hMax = useMetric ? 220.0 : 87.0;
    final String? hOverride = useMetric ? null : _fmtHeight(height);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('About You',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('We use this to calculate your calorie needs',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            // Unit toggle
            Row(
              children: [
                const Text('Units',
                    style: TextStyle(color: kTextSecondary, fontSize: 13)),
                const Spacer(),
                _UnitToggle(
                  leftLabel: 'lbs / ft',
                  rightLabel: 'kg / cm',
                  isRight: useMetric,
                  onChanged: onUseMetricChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Sex',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _SexChip(
                    label: 'Male',
                    value: 'M',
                    selected: sex,
                    onTap: onSexChanged),
                const SizedBox(width: 8),
                _SexChip(
                    label: 'Female',
                    value: 'F',
                    selected: sex,
                    onTap: onSexChanged),
                const SizedBox(width: 8),
                _SexChip(
                    label: 'Other',
                    value: 'O',
                    selected: sex,
                    onTap: onSexChanged),
              ],
            ),
            const SizedBox(height: 14),
            _SliderSection(
              label: 'Current Weight',
              value: wVal,
              unit: wUnit,
              min: wMin,
              max: wMax,
              displayOverride: null,
              onChanged: (v) =>
                  onWeightChanged(useMetric ? v : v / 2.20462),
            ),
            const SizedBox(height: 12),
            _SliderSection(
              label: 'Height',
              value: hVal,
              unit: useMetric ? 'cm' : '',
              min: hMin,
              max: hMax,
              displayOverride: hOverride,
              onChanged: (v) =>
                  onHeightChanged(useMetric ? v : v * 2.54),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRight;
  final ValueChanged<bool> onChanged;

  const _UnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(label: leftLabel, selected: !isRight,
              onTap: () => onChanged(false)),
          _ToggleOption(label: rightLabel, selected: isRight,
              onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kNeonYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : kTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _SexChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kNeonYellow : kCardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? kNeonYellow : const Color(0xFF2A3550),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : kTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SliderSection extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? displayOverride;

  const _SliderSection({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.displayOverride,
  });

  @override
  State<_SliderSection> createState() => _SliderSectionState();
}

class _SliderSectionState extends State<_SliderSection> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _displayValue(widget.value));
  }

  @override
  void didUpdateWidget(_SliderSection old) {
    super.didUpdateWidget(old);
    // Only sync text when not actively typing
    if (!_editing && old.value != widget.value) {
      _ctrl.text = _displayValue(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _displayValue(double v) {
    // Show whole numbers when the range uses whole numbers, else 1 decimal
    return (v == v.roundToDouble()) ? v.round().toString() : v.toStringAsFixed(1);
  }

  void _submitText() {
    final val = double.tryParse(_ctrl.text.trim());
    setState(() => _editing = false);
    if (val != null) {
      final clamped = val.clamp(widget.min, widget.max);
      widget.onChanged(clamped.toDouble());
    } else {
      // Restore current value if invalid input
      _ctrl.text = _displayValue(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final divisions = (widget.max - widget.min).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label,
                  style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // If there's a display override (e.g. ft/in for height), show it
                  if (widget.displayOverride != null) ...[
                    Text(
                      widget.displayOverride!,
                      style: const TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('(', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  ],
                  // Editable number field
                  IntrinsicWidth(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: widget.displayOverride != null ? kTextSecondary : kNeonYellow,
                        fontWeight: widget.displayOverride != null ? FontWeight.normal : FontWeight.bold,
                        fontSize: widget.displayOverride != null ? 13 : 18,
                        fontFamily: 'Poppins',
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onTap: () => setState(() => _editing = true),
                      onChanged: (_) => setState(() => _editing = true),
                      onSubmitted: (_) => _submitText(),
                      onEditingComplete: _submitText,
                    ),
                  ),
                  if (widget.displayOverride != null)
                    const Text(' in)', style: TextStyle(color: kTextSecondary, fontSize: 13))
                  else if (widget.unit.isNotEmpty)
                    Text(' ${widget.unit}',
                        style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kNeonYellow,
              inactiveTrackColor: const Color(0xFF2A3550),
              thumbColor: kNeonYellow,
              overlayColor: kNeonYellow.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              divisions: divisions > 0 ? divisions : null,
              onChanged: (v) {
                setState(() => _editing = false);
                widget.onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Goal ──────────────────────────────────────────────────────────────
class _Page3 extends StatelessWidget {
  final double goalWeight;  // always kg
  final String pace;
  final bool useMetric;
  final ValueChanged<double> onGoalWeightChanged;  // receives kg
  final ValueChanged<String> onPaceChanged;

  const _Page3({
    required this.goalWeight,
    required this.pace,
    required this.useMetric,
    required this.onGoalWeightChanged,
    required this.onPaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double gVal = useMetric ? goalWeight : goalWeight * 2.20462;
    final double gMin = useMetric ? 40.0 : 88.0;
    final double gMax = useMetric ? 180.0 : 397.0;
    final String gUnit = useMetric ? 'kg' : 'lbs';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Your Goal',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('How much do you want to weigh?',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 14),
            _SliderSection(
              label: 'Goal Weight',
              value: gVal,
              unit: gUnit,
              min: gMin,
              max: gMax,
              onChanged: (v) =>
                  onGoalWeightChanged(useMetric ? v : v / 2.20462),
            ),
            const SizedBox(height: 14),
            const Text('Loss Pace',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            _PaceOption(
              value: 'slow',
              title: 'Slow',
              subtitle: useMetric
                  ? '0.25 kg/week — Sustainable'
                  : '0.5 lbs/week — Sustainable',
              selected: pace,
              onTap: onPaceChanged,
            ),
            _PaceOption(
              value: 'steady',
              title: 'Steady',
              subtitle: useMetric
                  ? '0.5 kg/week — Recommended'
                  : '1 lb/week — Recommended',
              selected: pace,
              onTap: onPaceChanged,
            ),
            _PaceOption(
              value: 'aggressive',
              title: 'Aggressive',
              subtitle: useMetric
                  ? '1 kg/week — Challenging'
                  : '2 lbs/week — Challenging',
              selected: pace,
              onTap: onPaceChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceOption extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final String selected;
  final ValueChanged<String> onTap;

  const _PaceOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? kNeonYellow.withValues(alpha: 0.1) : kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? kNeonYellow : const Color(0xFF2A3550),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kNeonYellow : kTextSecondary,
                  width: 2,
                ),
                color:
                    isSelected ? kNeonYellow : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: isSelected ? kNeonYellow : kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 4: Activity Level ────────────────────────────────────────────────────
class _Page4 extends StatelessWidget {
  final String activityLevel;
  final ValueChanged<String> onActivityChanged;

  const _Page4({
    required this.activityLevel,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Activity Level',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
                'How active are you outside of dedicated workouts?',
                style:
                    TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 14),
            _ActivityOption(
              value: 'sedentary',
              title: 'Sedentary',
              subtitle: 'Little or no exercise',
              icon: Icons.chair_outlined,
              selected: activityLevel,
              onTap: onActivityChanged,
            ),
            _ActivityOption(
              value: 'lightly_active',
              title: 'Lightly Active',
              subtitle: 'Light exercise 1-3 days/week',
              icon: Icons.directions_walk,
              selected: activityLevel,
              onTap: onActivityChanged,
            ),
            _ActivityOption(
              value: 'moderate',
              title: 'Moderately Active',
              subtitle: 'Moderate exercise 3-5 days/week',
              icon: Icons.directions_run_outlined,
              selected: activityLevel,
              onTap: onActivityChanged,
            ),
            _ActivityOption(
              value: 'very_active',
              title: 'Very Active',
              subtitle: 'Hard exercise 6-7 days/week',
              icon: Icons.fitness_center,
              selected: activityLevel,
              onTap: onActivityChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityOption extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final String selected;
  final ValueChanged<String> onTap;

  const _ActivityOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? kNeonYellow.withValues(alpha: 0.1) : kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? kNeonYellow : const Color(0xFF2A3550),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? kNeonYellow.withValues(alpha: 0.2)
                    : const Color(0xFF2A3550),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected ? kNeonYellow : kTextSecondary,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color:
                            isSelected ? kNeonYellow : kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: kNeonYellow, size: 20),
          ],
        ),
      ),
    );
  }
}
