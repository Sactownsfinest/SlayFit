import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloud_sync_service.dart';
import '../home_screen.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  static const _testPhone = '+15555555555';
  static const _testOtp = '123456';

  Future<void> _sendCode() async {
    String raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    // Strip spaces, dashes, and parentheses for parsing
    final digits = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Auto-prepend +1 for US numbers if no country code given
    final phone = digits.startsWith('+') ? digits : '+1$digits';

    // Test account bypass for Google Play review
    if (phone == _testPhone) {
      setState(() { _codeSent = true; _isLoading = false; });
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verified (Android only)
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        String msg;
        if (e.code == 'billing-not-enabled') {
          msg = 'Phone sign-in is currently unavailable. Please use Google Sign-In instead.';
        } else if (e.code == 'invalid-phone-number') {
          msg = 'Invalid phone number. Please enter a valid US number.';
        } else {
          msg = e.message ?? 'Verification failed. Please try again.';
        }
        _showError(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyCode() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;
    setState(() => _isLoading = true);

    // Test account bypass for Google Play review
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final normalizedPhone = phone.startsWith('+') ? phone : '+1$phone';
    if (normalizedPhone == _testPhone && otp == _testOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _testPhone);
      await prefs.setBool('is_logged_in', true);
      final existing = prefs.getString('user_name') ?? '';
      if (existing.isEmpty) await prefs.setString('user_name', 'Test User');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.read(authProvider.notifier).completeOnboarding();
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      if (onboardingDone) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
      return;
    }

    if (_verificationId == null) return;
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      final uid = user?.uid ?? '';
      // Restore cloud data before navigating
      await CloudSyncService.restore(uid);
      await CloudSyncService.initUser(user?.phoneNumber ?? uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user?.phoneNumber ?? '');
      final existing = prefs.getString('user_name') ?? '';
      if (existing.isEmpty) {
        await prefs.setString('user_name', user?.displayName ?? 'User');
      }
      await prefs.setBool('is_logged_in', true);
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (onboardingDone) {
        ref.read(authProvider.notifier).completeOnboarding();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ref.read(authProvider.notifier).completeOnboarding();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message ?? 'Sign-in failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        backgroundColor: kPrimaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Phone Sign In', style: TextStyle(color: kTextPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                _codeSent ? 'Enter the code' : 'Your phone number',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_phoneController.text.trim()}'
                    : 'Enter your number with country code (e.g. +1 555 000 0000)',
                style: const TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 36),
              if (!_codeSent)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: kTextSecondary),
                    hintText: '+1 555 000 0000',
                    hintStyle: TextStyle(color: kTextSecondary),
                  ),
                ),
              if (_codeSent)
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline, color: kTextSecondary),
                  ),
                  onSubmitted: (_) => _verifyCode(),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _codeSent ? 'Verify Code' : 'Send Code',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  }),
                  child: const Text(
                    'Change phone number',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
