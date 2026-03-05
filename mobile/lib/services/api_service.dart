import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/health_model.dart';

class ApiService {
  late SharedPreferences _prefs;
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get _authToken => _prefs.getString('auth_token');

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ============ Authentication ============
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _prefs.setString('auth_token', data['access_token']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _prefs.setString('auth_token', data['access_token']);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _init();
    await _prefs.remove('auth_token');
  }

  // ============ User Profile ============
  Future<User> getCurrentUser() async {
    await _init();
    
    final response = await http.get(
      Uri.parse(ApiEndpoints.userProfile),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user: ${response.body}');
    }
  }

  Future<UserProfile> getUserProfile() async {
    await _init();
    
    final response = await http.get(
      Uri.parse(ApiEndpoints.userProfile),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    await _init();
    
    final response = await http.put(
      Uri.parse(ApiEndpoints.updateProfile),
      headers: _headers,
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // ============ Food Logging ============
  Future<FoodLog> createFoodLog(FoodLog foodLog) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.foodLogs),
      headers: _headers,
      body: jsonEncode(foodLog.toJson()),
    );

    if (response.statusCode == 201) {
      return FoodLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to log food: ${response.body}');
    }
  }

  Future<List<FoodLog>> getFoodLogsToday() async {
    await _init();
    
    final response = await http.get(
      Uri.parse(ApiEndpoints.foodLogsToday),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => FoodLog.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch food logs: ${response.body}');
    }
  }

  Future<List<FoodLog>> getFoodLogs({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _init();
    
    final response = await http.get(
      Uri.parse('${ApiEndpoints.foodLogs}?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => FoodLog.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch food logs: ${response.body}');
    }
  }

  Future<void> deleteFoodLog(int foodLogId) async {
    await _init();
    
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.deleteFood}/$foodLogId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete food log: ${response.body}');
    }
  }

  // ============ Weight Tracking ============
  Future<WeightEntry> recordWeight(WeightEntry entry) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.recordWeight),
      headers: _headers,
      body: jsonEncode(entry.toJson()),
    );

    if (response.statusCode == 201) {
      return WeightEntry.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to record weight: ${response.body}');
    }
  }

  Future<List<WeightEntry>> getWeightHistory({int days = 90}) async {
    await _init();
    
    final response = await http.get(
      Uri.parse('${ApiEndpoints.weightEntries}?days=$days'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => WeightEntry.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch weight history: ${response.body}');
    }
  }

  // ============ Activities ============
  Future<Activity> createActivity(Activity activity) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.activities),
      headers: _headers,
      body: jsonEncode(activity.toJson()),
    );

    if (response.statusCode == 201) {
      return Activity.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to log activity: ${response.body}');
    }
  }

  Future<List<Activity>> getActivitiesToday() async {
    await _init();
    
    final response = await http.get(
      Uri.parse(ApiEndpoints.activitiesToday),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Activity.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch activities: ${response.body}');
    }
  }

  // ============ Diary ============
  Future<DiaryEntry> createDiaryEntry(DiaryEntry entry) async {
    await _init();
    
    final response = await http.post(
      Uri.parse(ApiEndpoints.diaryEntries),
      headers: _headers,
      body: jsonEncode(entry.toJson()),
    );

    if (response.statusCode == 201) {
      return DiaryEntry.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create diary entry: ${response.body}');
    }
  }

  Future<DiaryEntry?> getDiaryToday() async {
    await _init();
    
    final response = await http.get(
      Uri.parse(ApiEndpoints.diaryToday),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return DiaryEntry.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch diary: ${response.body}');
    }
  }

  // ============ Food Search ============
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    await _init();
    
    final response = await http.get(
      Uri.parse('${ApiEndpoints.foodDatabase}?q=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search food: ${response.body}');
    }
  }
}
