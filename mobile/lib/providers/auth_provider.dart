import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? error;

  const AuthState({required this.status, this.error});

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated() => const AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    state = loggedIn ? AuthState.authenticated() : AuthState.unauthenticated();
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState.loading();
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('user_email');
    final storedPassword = prefs.getString('user_password');
    if (storedEmail == email && storedPassword == password) {
      await prefs.setBool('is_logged_in', true);
      state = AuthState.authenticated();
    } else {
      state = AuthState.unauthenticated(error: 'Invalid email or password');
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    state = AuthState.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await prefs.setBool('is_logged_in', true);
    state = AuthState.authenticated();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
