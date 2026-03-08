import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';

/// One-way hash for local password storage. Never stored in plaintext.
String _hashPassword(String email, String password) {
  final input = '${email.toLowerCase().trim()}:$password:slayfit_v1';
  return sha256.convert(utf8.encode(input)).toString();
}

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
    final email = prefs.getString('user_email');

    if (!loggedIn || email == null || email.isEmpty) {
      // Try silent Google sign-in — restores session after reinstall or data clear
      final didRestore = await _trySilentGoogleSignIn();
      if (!didRestore) {
        await prefs.setBool('is_logged_in', false);
        state = AuthState.unauthenticated();
      }
      return;
    }

    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    state = onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
  }

  /// Attempts a silent Google sign-in (no UI shown). Restores Firestore data.
  /// Returns true if sign-in succeeded and state was updated.
  Future<bool> _trySilentGoogleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signInSilently();
      if (googleUser == null) return false;
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
      final restored = await CloudSyncService.restore(uid);
      if (!restored) {
        final emailUid = CloudSyncService.emailToUid(email);
        if (emailUid != uid) await CloudSyncService.restore(emailUid);
      }
      final prefs = await SharedPreferences.getInstance();
      final existingName = prefs.getString('user_name') ?? '';
      if (existingName.isEmpty) {
        await prefs.setString(
            'user_name', user?.displayName ?? googleUser.displayName ?? '');
      }
      await prefs.setString('user_email', email);
      await prefs.setBool('is_logged_in', true);
      await CloudSyncService.initUser(email);
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      state = onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState.loading();
    final prefs = await SharedPreferences.getInstance();
    var storedEmail = prefs.getString('user_email');

    // On fresh install or wiped device, local credentials are gone.
    // Attempt a cloud restore first so we can validate against restored data.
    if (storedEmail == null) {
      await CloudSyncService.restore(CloudSyncService.emailToUid(email));
      storedEmail = prefs.getString('user_email');
    }

    final storedHash = prefs.getString('user_password_hash');
    // Also accept old plaintext entries so existing users aren't locked out,
    // then migrate them to the hashed format on successful login.
    final oldPlaintext = prefs.getString('user_password');
    final hashMatches = storedHash == _hashPassword(email, password);
    final plaintextMatches = oldPlaintext != null && oldPlaintext == password;
    // After a cloud restore, password_hash is missing (sensitive key — not synced).
    // If the email matches what was restored, trust the provided password and re-set the hash.
    final restoredWithoutHash =
        storedEmail == email && storedHash == null && oldPlaintext == null;

    if (storedEmail == email && (hashMatches || plaintextMatches || restoredWithoutHash)) {
      // Migrate plaintext → hash, or re-set hash after cloud restore
      if (plaintextMatches && !hashMatches) {
        await prefs.setString('user_password_hash', _hashPassword(email, password));
        await prefs.remove('user_password');
      } else if (restoredWithoutHash) {
        await prefs.setString('user_password_hash', _hashPassword(email, password));
      }
      await CloudSyncService.initUser(email);
      await prefs.setBool('is_logged_in', true);
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      state = onboardingDone ? AuthState.authenticated() : AuthState.onboarding();
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
    await prefs.setString('user_password_hash', _hashPassword(email, password));
    await prefs.remove('user_password'); // clear any old plaintext
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
