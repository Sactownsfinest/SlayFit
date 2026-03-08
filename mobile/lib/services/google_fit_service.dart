import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Google Fit REST API integration.
/// Uses the existing google_sign_in package with Fitness API scopes.
///
/// SETUP REQUIRED (one-time, in Google Cloud Console):
/// 1. Enable "Fitness API" in your Firebase/Google Cloud project
/// 2. No extra OAuth client needed — same client_id as your Google Sign-In
class GoogleFitService {
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.body.read',
    ],
  );

  static GoogleSignInAccount? _account;

  static bool get isSignedIn => _account != null;

  /// Interactive sign-in flow.
  static Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      return _account != null;
    } catch (_) {
      return false;
    }
  }

  /// Silent sign-in on app startup (restores existing session).
  static Future<bool> signInSilently() async {
    try {
      _account = await _googleSignIn.signInSilently();
      return _account != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  static Future<String?> _getAccessToken() async {
    if (_account == null) return null;
    try {
      final auth = await _account!.authentication;
      return auth.accessToken;
    } catch (_) {
      // Token expired — try silent refresh
      try {
        _account = await _googleSignIn.signInSilently();
        final auth = await _account?.authentication;
        return auth?.accessToken;
      } catch (_) {
        return null;
      }
    }
  }

  /// Fetch today's steps and active calories from Google Fit.
  /// Returns {'steps': int, 'calories': int} or null on failure.
  static Future<Map<String, dynamic>?> fetchTodayData() async {
    final token = await _getAccessToken();
    if (token == null) return null;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final body = jsonEncode({
      'aggregateBy': [
        {'dataTypeName': 'com.google.step_count.delta'},
        {'dataTypeName': 'com.google.calories.expended'},
      ],
      'bucketByTime': {'durationMillis': 86400000},
      'startTimeMillis': midnight.millisecondsSinceEpoch,
      'endTimeMillis': now.millisecondsSinceEpoch,
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 401) {
        // Token expired mid-session — sign out so user can reconnect
        _account = null;
        return null;
      }
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final buckets = json['bucket'] as List? ?? [];

      int steps = 0;
      double calories = 0;

      for (final bucket in buckets) {
        final datasets = bucket['dataset'] as List? ?? [];
        for (final dataset in datasets) {
          final id = (dataset['dataSourceId'] as String?) ?? '';
          final points = dataset['point'] as List? ?? [];
          for (final point in points) {
            final values = point['value'] as List? ?? [];
            if (values.isEmpty) continue;
            if (id.contains('step_count')) {
              steps += (values[0]['intVal'] as int? ?? 0);
            } else if (id.contains('calories')) {
              calories += (values[0]['fpVal'] as double? ?? 0.0);
            }
          }
        }
      }

      return {'steps': steps, 'calories': calories.toInt()};
    } catch (_) {
      return null;
    }
  }
}
