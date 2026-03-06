import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  String _sex = 'M';
  double _weight = 80;
  double _height = 170;
  double _goalWeight = 70;
  String _pace = 'steady';
  String _activityLevel = 'moderate';

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
    final calories = _calculateCalorieGoal();
    final profile = ref.read(userProfileProvider).copyWith(
          sex: _sex,
          heightCm: _height,
          goalWeightKg: _goalWeight,
          activityLevel: _activityLevel,
          dailyCalorieGoal: calories,
        );
    await ref.read(userProfileProvider.notifier).update(profile);
    ref.read(weightProvider.notifier).logWeight(_weight);
    ref.read(foodLogProvider.notifier).setCalorieGoal(calories.toDouble());
    ref.read(authProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: PageView(
        controller: _pageController,
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _Page1(),
          _Page2(
            sex: _sex,
            weight: _weight,
            height: _height,
            onSexChanged: (v) => setState(() => _sex = v),
            onWeightChanged: (v) => setState(() => _weight = v),
            onHeightChanged: (v) => setState(() => _height = v),
          ),
          _Page3(
            goalWeight: _goalWeight,
            pace: _pace,
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
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text("Let's Go!",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────
class _Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kNeonYellow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.bolt, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 28),
            const Text(
              'Welcome to SLAYFIT',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your intelligent weight loss companion.\nLet us set up your personalized plan.',
              style: TextStyle(
                  color: kTextSecondary, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _FeatureRow(
                icon: Icons.restaurant_outlined,
                text: 'Track food & calories'),
            const SizedBox(height: 14),
            _FeatureRow(
                icon: Icons.fitness_center_outlined,
                text: 'Log workouts & activity'),
            const SizedBox(height: 14),
            _FeatureRow(
                icon: Icons.trending_down,
                text: 'Monitor your weight loss'),
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
  final double weight;
  final double height;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onHeightChanged;

  const _Page2({
    required this.sex,
    required this.weight,
    required this.height,
    required this.onSexChanged,
    required this.onWeightChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('About You',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('We use this to calculate your calorie needs',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            const Text('Sex',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                _SexChip(
                    label: 'Male',
                    value: 'M',
                    selected: sex,
                    onTap: onSexChanged),
                const SizedBox(width: 10),
                _SexChip(
                    label: 'Female',
                    value: 'F',
                    selected: sex,
                    onTap: onSexChanged),
                const SizedBox(width: 10),
                _SexChip(
                    label: 'Other',
                    value: 'O',
                    selected: sex,
                    onTap: onSexChanged),
              ],
            ),
            const SizedBox(height: 28),
            _SliderSection(
              label: 'Current Weight',
              value: weight,
              unit: 'kg',
              min: 40,
              max: 200,
              onChanged: onWeightChanged,
            ),
            const SizedBox(height: 24),
            _SliderSection(
              label: 'Height',
              value: height,
              unit: 'cm',
              min: 140,
              max: 220,
              onChanged: onHeightChanged,
            ),
          ],
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

class _SliderSection extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(label,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 13)),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: kNeonYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                  ),
                ]),
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
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Goal ──────────────────────────────────────────────────────────────
class _Page3 extends StatelessWidget {
  final double goalWeight;
  final String pace;
  final ValueChanged<double> onGoalWeightChanged;
  final ValueChanged<String> onPaceChanged;

  const _Page3({
    required this.goalWeight,
    required this.pace,
    required this.onGoalWeightChanged,
    required this.onPaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Your Goal',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('How much do you want to weigh?',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            _SliderSection(
              label: 'Goal Weight',
              value: goalWeight,
              unit: 'kg',
              min: 40,
              max: 180,
              onChanged: onGoalWeightChanged,
            ),
            const SizedBox(height: 28),
            const Text('Loss Pace',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            _PaceOption(
              value: 'slow',
              title: 'Slow',
              subtitle: '0.25 kg/week — Sustainable',
              selected: pace,
              onTap: onPaceChanged,
            ),
            _PaceOption(
              value: 'steady',
              title: 'Steady',
              subtitle: '0.5 kg/week — Recommended',
              selected: pace,
              onTap: onPaceChanged,
            ),
            _PaceOption(
              value: 'aggressive',
              title: 'Aggressive',
              subtitle: '1 kg/week — Challenging',
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
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Activity Level',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'How active are you outside of dedicated workouts?',
                style:
                    TextStyle(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 32),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? kNeonYellow.withValues(alpha: 0.2)
                    : const Color(0xFF2A3550),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? kNeonYellow : kTextSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
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
