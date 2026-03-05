class User {
  final int id;
  final String email;
  final String username;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserProfile {
  final int id;
  final int userId;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? sex;
  final double? heightCm;
  final double? currentWeightKg;
  final double? goalWeightKg;
  final int? goalTimelineWeeks;
  final String? preferredPace;
  final String? activityLevel;
  final double? sleepHours;
  final String? stressLevel;
  final String? dietaryPreferences;
  final String? allergies;
  final String? culturalFoods;
  final bool isPregnant;
  final String? dietaryRestrictions;
  final String? motivationWhy;
  final String? preferredCoachingStyle;
  final double? tdee;
  final double? calorieTarget;
  final bool onboardingCompleted;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    this.currentWeightKg,
    this.goalWeightKg,
    this.goalTimelineWeeks,
    this.preferredPace,
    this.activityLevel,
    this.sleepHours,
    this.stressLevel,
    this.dietaryPreferences,
    this.allergies,
    this.culturalFoods,
    this.isPregnant = false,
    this.dietaryRestrictions,
    this.motivationWhy,
    this.preferredCoachingStyle,
    this.tdee,
    this.calorieTarget,
    this.onboardingCompleted = false,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      sex: json['sex'],
      heightCm: json['height_cm']?.toDouble(),
      currentWeightKg: json['current_weight_kg']?.toDouble(),
      goalWeightKg: json['goal_weight_kg']?.toDouble(),
      goalTimelineWeeks: json['goal_timeline_weeks'],
      preferredPace: json['preferred_pace'],
      activityLevel: json['activity_level'],
      sleepHours: json['sleep_hours']?.toDouble(),
      stressLevel: json['stress_level'],
      dietaryPreferences: json['dietary_preferences'],
      allergies: json['allergies'],
      culturalFoods: json['cultural_foods'],
      isPregnant: json['is_pregnant'] ?? false,
      dietaryRestrictions: json['dietary_restrictions'],
      motivationWhy: json['motivation_why'],
      preferredCoachingStyle: json['preferred_coaching_style'],
      tdee: json['tdee']?.toDouble(),
      calorieTarget: json['calorie_target']?.toDouble(),
      onboardingCompleted: json['onboarding_completed'] ?? false,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'goal_weight_kg': goalWeightKg,
      'goal_timeline_weeks': goalTimelineWeeks,
      'preferred_pace': preferredPace,
      'activity_level': activityLevel,
      'sleep_hours': sleepHours,
      'stress_level': stressLevel,
      'dietary_preferences': dietaryPreferences,
      'allergies': allergies,
      'cultural_foods': culturalFoods,
      'is_pregnant': isPregnant,
      'dietary_restrictions': dietaryRestrictions,
      'motivation_why': motivationWhy,
      'preferred_coaching_style': preferredCoachingStyle,
      'tdee': tdee,
      'calorie_target': calorieTarget,
      'onboarding_completed': onboardingCompleted,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
