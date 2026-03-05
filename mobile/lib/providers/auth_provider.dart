import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

final authProvider = FutureProvider<User?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  if (token == null) {
    return null;
  }
  
  try {
    final apiService = ref.watch(apiServiceProvider);
    final user = await apiService.getCurrentUser();
    return user;
  } catch (e) {
    // Token might be invalid
    await prefs.remove('auth_token');
    return null;
  }
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return null;
  
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserProfile();
});

final apiServiceProvider = Provider((ref) {
  return ApiService();
});

final authTokenProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
});
