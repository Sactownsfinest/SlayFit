import 'package:flutter/material.dart';
import '../main.dart';

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _step = 0;

  static const _steps = [
    _Step(
      emoji: '⚡',
      title: 'Welcome to SlayFit!',
      body: 'Your personalized weight loss and fitness companion. '
          'This quick tour shows you everything the app can do.',
    ),
    _Step(
      emoji: '🏠',
      title: 'Dashboard',
      body: 'Your daily calorie ring, macro breakdown, water tracker, '
          'and streak — all at a glance. Tap the glowing bolt ⚡ anytime '
          'to chat with your AI Coach.',
    ),
    _Step(
      emoji: '🍽️',
      title: 'Food Log',
      body: 'Search millions of foods, scan barcodes, or use meal templates '
          'to log what you eat. Your macros update instantly.',
    ),
    _Step(
      emoji: '💪',
      title: 'Activity',
      body: 'Log workouts from 16 built-in plans or create your own. '
          'Watch guided classes and track every rep and set.',
    ),
    _Step(
      emoji: '📈',
      title: 'Progress',
      body: 'See your 7-day calorie trend, weight history, and measurements. '
          'Share your progress photos with the community.',
    ),
    _Step(
      emoji: '👥',
      title: 'Community',
      body: 'Chat with the SlayFit community, share recipes, and join '
          'challenges together. Post your wins and stay accountable.',
    ),
    _Step(
      emoji: '🏆',
      title: 'Challenges',
      body: 'Accept daily, weekly, and 30-day challenges. Invite friends '
          'and see everyone\'s live progress in the Accountability section. '
          'Tap 👊 Nudge to motivate a friend who\'s slacking!',
    ),
    _Step(
      emoji: '👤',
      title: 'Profile & Settings',
      body: 'Update your stats, connect Fitbit or Google Fit, set '
          'reminders, and customize your calorie and water goals. '
          'Everything stays synced across your devices.',
    ),
    _Step(
      emoji: '🔔',
      title: 'Notifications',
      body: 'Tap the bell 🔔 in any screen to see challenge invites, '
          'nudges from friends, and achievement alerts. '
          'Accept challenges right from the notification — the panel '
          'stays open so you can handle them all at once.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Dialog(
      backgroundColor: kSurfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(step.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _step ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _step
                        ? kNeonYellow
                        : const Color(0xFF2A3550),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextSecondary,
                        side: const BorderSide(color: Color(0xFF2A3550)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLast
                        ? () => Navigator.of(context).pop()
                        : () => setState(() => _step++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isLast ? "Let's Slay! ⚡" : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Skip tour',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String emoji;
  final String title;
  final String body;
  const _Step({required this.emoji, required this.title, required this.body});
}
