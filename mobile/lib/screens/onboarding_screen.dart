import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        children: const [
          _OnboardingPage1(),
          _OnboardingPage2(),
          _OnboardingPage3(),
          _OnboardingPage4(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton.icon(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              )
            else
              const SizedBox(width: 100),
            Row(
              children: List.generate(
                4,
                (index) => Container(
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            if (_currentPage < 3)
              ElevatedButton.icon(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                label: const Text('Next'),
                icon: const Icon(Icons.arrow_forward),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // TODO: Complete onboarding
                },
                child: const Text('Get Started'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.trending_down,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to SlayFit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your intelligent weight loss companion',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: const Text('Track everything'),
                      subtitle: const Text('Food, weight, and activities'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: const Text('Smart coaching'),
                      subtitle: const Text('Personalized insights'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: const Text('Stay motivated'),
                      subtitle: const Text('Daily reminders & support'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage2 extends StatefulWidget {
  const _OnboardingPage2();

  @override
  State<_OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<_OnboardingPage2> {
  String? selectedSex;
  double weight = 70;
  double height = 170;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Tell us about yourself',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'M', label: Text('Male')),
                ButtonSegment<String>(value: 'F', label: Text('Female')),
                ButtonSegment<String>(value: 'O', label: Text('Other')),
              ],
              selected: <String>{selectedSex ?? 'M'},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => selectedSex = newSelection.first);
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Height: ${height.toStringAsFixed(0)} cm'),
                    Slider(
                      value: height,
                      min: 140,
                      max: 220,
                      onChanged: (value) => setState(() => height = value),
                    ),
                    const SizedBox(height: 24),
                    Text('Weight: ${weight.toStringAsFixed(1)} kg'),
                    Slider(
                      value: weight,
                      min: 30,
                      max: 200,
                      onChanged: (value) => setState(() => weight = value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage3 extends StatefulWidget {
  const _OnboardingPage3();

  @override
  State<_OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<_OnboardingPage3> {
  double goalWeight = 65;
  String selectedPace = 'steady';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'What\'s your goal?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Goal weight: ${goalWeight.toStringAsFixed(1)} kg'),
                    Slider(
                      value: goalWeight,
                      min: 30,
                      max: 150,
                      onChanged: (value) => setState(() => goalWeight = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preferred pace',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...['slow', 'steady', 'aggressive'].map((pace) {
              return RadioListTile(
                title: Text(pace.capitalize()),
                subtitle: Text(_getPaceDescription(pace)),
                value: pace,
                groupValue: selectedPace,
                onChanged: (value) => setState(() => selectedPace = value!),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getPaceDescription(String pace) {
    switch (pace) {
      case 'slow':
        return '0.25 kg/week - Easiest';
      case 'steady':
        return '0.5 kg/week - Balanced';
      case 'aggressive':
        return '1 kg/week - Fastest';
      default:
        return '';
    }
  }
}

class _OnboardingPage4 extends StatefulWidget {
  const _OnboardingPage4();

  @override
  State<_OnboardingPage4> createState() => _OnboardingPage4State();
}

class _OnboardingPage4State extends State<_OnboardingPage4> {
  String selectedActivity = 'moderate';
  String selectedCoachingStyle = 'motivational';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Personalize your experience',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Activity Level',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...['sedentary', 'lightly_active', 'moderate', 'very_active'].map((level) {
              return RadioListTile(
                title: Text(level.replaceAll('_', ' ').capitalize()),
                value: level,
                groupValue: selectedActivity,
                onChanged: (value) => setState(() => selectedActivity = value!),
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(
              'Coaching Style',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...['gentle', 'motivational', 'strict'].map((style) {
              return RadioListTile(
                title: Text(style.capitalize()),
                value: style,
                groupValue: selectedCoachingStyle,
                onChanged: (value) => setState(() => selectedCoachingStyle = value!),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
