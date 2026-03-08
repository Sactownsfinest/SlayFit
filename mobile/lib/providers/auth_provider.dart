import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';

enum AuthStatus { loading, authenticated, onboarding, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? error;

  const AuthState({required this.status, this.error});

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated() =>
      const AuthState(status: AuthStatus.authenticated);
  factory AuthState.onboarding() =>
      const AuthState(status: AuthStatus.onboarding);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    await CloudSyncService.loadUserId();
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!loggedIn) {
      state = AuthState.unauthenticated();
      return;
    }
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    state = onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState.loading();
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('user_email');
    final storedPassword = prefs.getString('user_password');
    if (storedEmail == email && storedPassword == password) {
      // Restore cloud data before navigating to home
      await CloudSyncService.restore(CloudSyncService.emailToUid(email));
      await prefs.setBool('is_logged_in', true);
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      state =
          onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
    } else {
      state = AuthState.unauthenticated(error: 'Invalid email or password');
    }
  }

  Future<void> signUpWithEmail(
      String name, String email, String password) async {
    state = AuthState.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('onboarding_completed', false);
    await CloudSyncService.initUser(email);
    state = AuthState.onboarding();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    CloudSyncService.uploadValue('onboarding_completed', true);
    state = AuthState.authenticated();
  }

  Future<void> signInWithGoogle() async {
    state = AuthState.loading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = AuthState.unauthenticated();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      final uid = user?.uid ?? '';
      final email = user?.email ?? googleUser.email;
      // Try restoring with Firebase UID first, then fall back to email-hash UID
      // (covers users who originally signed up with email/password)
      final restored = await CloudSyncService.restore(uid);
      if (!restored) {
        final emailUid = CloudSyncService.emailToUid(email);
        if (emailUid != uid) await CloudSyncService.restore(emailUid);
      }
      final prefs = await SharedPreferences.getInstance();
      // Preserve existing name if already set from a previous login/onboarding
      final existingName = prefs.getString('user_name') ?? '';
      if (existingName.isEmpty) {
        await prefs.setString('user_name', user?.displayName ?? googleUser.displayName ?? '');
      }
      await prefs.setString('user_email', email);
      await prefs.setBool('is_logged_in', true);
      await CloudSyncService.initUser(email);
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      state = onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
    } catch (e) {
      state = AuthState.unauthenticated(error: 'Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
