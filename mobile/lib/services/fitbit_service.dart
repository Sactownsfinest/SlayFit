import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------
// SETUP REQUIRED:
// 1. Go to dev.fitbit.com and create a new app
// 2. Set OAuth 2.0 Application Type = "Personal"
// 3. Set Callback URL = com.slayfit.slayfit://oauthredirect
// 4. Copy your Client ID below
// ---------------------------------------------------------------
const kFitbitClientId = '23TY7F';
const _kFitbitClientSecret = 'bbe5a365b7b2992ee5383f5663dffb38';

const _redirectUri = 'com.slayfit.slayfit://oauthredirect';
const _scopes = 'activity weight';
const _tokenEndpoint = 'https://api.fitbit.com/oauth2/token';
const _keyAccess = 'fitbit_access_token';
const _keyRefresh = 'fitbit_refresh_token';
const _keyExpiry = 'fitbit_token_expiry';

class FitbitService {
  static final FitbitService _instance = FitbitService._();
  factory FitbitService() => _instance;
  FitbitService._();

  bool get isConfigured => kFitbitClientId != 'YOUR_FITBIT_CLIENT_ID';

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<bool> authenticate() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final authUrl = Uri.https('www.fitbit.com', '/oauth2/authorize', {
      'client_id': kFitbitClientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': _scopes,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'com.slayfit.slayfit',
      options: const FlutterWebAuth2Options(preferEphemeral: true),
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw Exception('No authorization code returned');

    final basicAuth = base64Encode(utf8.encode('$kFitbitClientId:$_kFitbitClientSecret'));
    final tokenResponse = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $basicAuth',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
    ).timeout(const Duration(seconds: 30));

    if (tokenResponse.statusCode != 200) {
      throw Exception(
          'Token exchange failed (${tokenResponse.statusCode}): ${tokenResponse.body}');
    }

    final data = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    await _saveTokens(
      data['access_token'] as String?,
      data['refresh_token'] as String?,
      DateTime.now().add(Duration(seconds: expiresIn)),
    );
    return true;
  }

  Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_keyAccess);
    final refresh = prefs.getString(_keyRefresh);
    final expiryMs = prefs.getInt(_keyExpiry);
    if (access == null || refresh == null) return null;
    final expiry = expiryMs != null
        ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
        : DateTime.now().subtract(const Duration(seconds: 1));
    if (DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)))) {
      return _refreshToken(refresh);
    }
    return access;
  }

  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final basicAuth = base64Encode(utf8.encode('$kFitbitClientId:$_kFitbitClientSecret'));
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $basicAuth',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
        await _saveTokens(
          data['access_token'] as String?,
          data['refresh_token'] as String?,
          DateTime.now().add(Duration(seconds: expiresIn)),
        );
        return data['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveTokens(
      String? access, String? refresh, DateTime? expiry) async {
    final prefs = await SharedPreferences.getInstance();
    if (access != null) await prefs.setString(_keyAccess, access);
    if (refresh != null) await prefs.setString(_keyRefresh, refresh);
    if (expiry != null) {
      await prefs.setInt(_keyExpiry, expiry.millisecondsSinceEpoch);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyExpiry);
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Activity summary for a specific date (YYYY-MM-DD)
  Future<Map<String, dynamic>?> fetchActivitySummaryForDate(String date) async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    try {
      final uri = Uri.parse('https://api.fitbit.com/1/user/-/activities/date/$date.json');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final summary = data['summary'] as Map<String, dynamic>?;
      if (summary == null) return null;
      return {
        'steps': (summary['steps'] as num?)?.toInt() ?? 0,
        'activityCalories': (summary['caloriesOut'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  // Daily activity summary — steps + active calories burned
  Future<Map<String, dynamic>?> fetchTodayActivitySummary() async {
    final token = await getValidAccessToken();
    if (token == null) throw Exception('No valid Fitbit token — please reconnect.');
    final uri = Uri.parse(
        'https://api.fitbit.com/1/user/-/activities/date/$_todayDate.json');
    final resp = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 401) throw Exception('Fitbit token rejected (401) — please reconnect.');
    if (resp.statusCode != 200) throw Exception('Fitbit API error ${resp.statusCode}: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final summary = data['summary'] as Map<String, dynamic>?;
    if (summary == null) return null;
    return {
      'steps': (summary['steps'] as num?)?.toInt() ?? 0,
      'activityCalories': (summary['caloriesOut'] as num?)?.toInt() ?? 0,
      'activeMinutes': ((summary['fairlyActiveMinutes'] as num?)?.toInt() ?? 0) +
          ((summary['veryActiveMinutes'] as num?)?.toInt() ?? 0),
    };
  }

  // 15-min intraday steps — requires Personal app type on dev.fitbit.com
  Future<int?> fetchTodaySteps() async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    try {
      final uri = Uri.parse(
          'https://api.fitbit.com/1/user/-/activities/steps/date/today/1d/15min.json');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final dataset =
            (data['activities-steps-intraday']?['dataset'] as List?) ?? [];
        int total = dataset.fold<int>(
            0, (sum, item) => sum + ((item['value'] as num?)?.toInt() ?? 0));
        if (total == 0) {
          final daily = (data['activities-steps'] as List?)?.firstOrNull;
          total = int.tryParse(daily?['value']?.toString() ?? '0') ?? 0;
        }
        return total;
      }
    } catch (_) {}
    return null;
  }

  Future<double?> fetchLatestWeightKg() async {
    final token = await getValidAccessToken();
    if (token == null) return null; // Weight is optional — don't block on this
    try {
      final uri = Uri.parse(
          'https://api.fitbit.com/1/user/-/body/log/weight/date/$_todayDate/1m.json');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final logs = data['weight'] as List?;
        if (logs != null && logs.isNotEmpty) {
          return (logs.last['weight'] as num?)?.toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> fetchDisplayName() async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    try {
      final uri = Uri.parse('https://api.fitbit.com/1/user/-/profile.json');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['user']?['displayName'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
