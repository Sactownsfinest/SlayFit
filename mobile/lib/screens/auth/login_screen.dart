import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import 'email_login_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo & branding
              Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
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
                  const SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'SLAYFIT',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        'BY SHENNEL',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: kNeonYellow,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Move. Sweat. Slay.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Auth buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SocialButton(
                    label: 'Continue with Google',
                    icon: _GoogleIcon(),
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF2A3550))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: kTextSecondary, fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF2A3550))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kNeonYellow,
                      side: const BorderSide(color: kNeonYellow, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue with Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw colored segments approximating the Google logo
    final segments = [
      (Colors.red, -0.1, 0.9),
      (Colors.yellow, 0.9, 1.9),
      (Colors.green, 1.9, 2.7),
      (Colors.blue, 2.7, 3.7),
    ];

    for (final s in segments) {
      final paint = Paint()
        ..color = s.$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.25;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        s.$2,
        s.$3 - s.$2,
        false,
        paint,
      );
    }

    // White cutout for the "G" gap
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height * 0.3, size.width / 2, size.height * 0.4),
      cutPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.42, size.width * 0.5, size.height * 0.16),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
