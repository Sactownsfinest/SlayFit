import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';

class UserProfile {
  final String name;
  final String email;
  final double heightCm;
  final String sex; // M, F, O
  final String activityLevel; // sedentary, lightly_active, moderate, very_active
  final double goalWeightKg;
  final int dailyCalorieGoal;
  final bool useMetric;

  const UserProfile({
    this.name = 'User',
    this.email = '',
    this.heightCm = 170,
    this.sex = 'M',
    this.activityLevel = 'moderate',
    this.goalWeightKg = 70,
    this.dailyCalorieGoal = 2000,
    this.useMetric = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? 'User',
        email: j['email'] ?? '',
        heightCm: (j['heightCm'] ?? 170).toDouble(),
        sex: j['sex'] ?? 'M',
        activityLevel: j['activityLevel'] ?? 'moderate',
        goalWeightKg: (j['goalWeightKg'] ?? 70).toDouble(),
        dailyCalorieGoal: j['dailyCalorieGoal'] ?? 2000,
        useMetric: j['useMetric'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'heightCm': heightCm,
        'sex': sex,
        'activityLevel': activityLevel,
        'goalWeightKg': goalWeightKg,
        'dailyCalorieGoal': dailyCalorieGoal,
        'useMetric': useMetric,
      };

  UserProfile copyWith({
    String? name,
    String? email,
    double? heightCm,
    String? sex,
    String? activityLevel,
    double? goalWeightKg,
    int? dailyCalorieGoal,
    bool? useMetric,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        heightCm: heightCm ?? this.heightCm,
        sex: sex ?? this.sex,
        activityLevel: activityLevel ?? this.activityLevel,
        goalWeightKg: goalWeightKg ?? this.goalWeightKg,
        dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
        useMetric: useMetric ?? this.useMetric,
      );

  String get activityLevelLabel {
    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderate':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      default:
        return 'Moderately Active';
    }
  }

  // Macro goals based on calorie target (25% protein, 45% carbs, 30% fat)
  int get proteinGoalG => (dailyCalorieGoal * 0.25 / 4).round();
  int get carbsGoalG => (dailyCalorieGoal * 0.45 / 4).round();
  int get fatGoalG => (dailyCalorieGoal * 0.30 / 9).round();
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('user_profile');
    final name = prefs.getString('user_name') ?? 'User';
    final email = prefs.getString('user_email') ?? '';
    if (json != null) {
      final profile = UserProfile.fromJson(jsonDecode(json));
      state = profile.copyWith(name: name, email: email);
    } else {
      state = state.copyWith(name: name, email: email);
    }
  }

  Future<void> update(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(profile.toJson());
    await prefs.setString('user_profile', encoded);
    // Sync calorie goal for food provider to pick up on next load
    await prefs.setDouble('calorie_goal', profile.dailyCalorieGoal.toDouble());
    CloudSyncService.upload('user_profile', encoded);
  }

  Future<void> refreshFromPrefs() async {
    await _load();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
