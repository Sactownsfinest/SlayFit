class FoodLog {
  final int id;
  final int userId;
  final DateTime loggedAt;
  final String foodName;
  final double calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final String? portionSize;
  final double? quantity;
  final String? unit;
  final String? imageUrl;
  final double? aiConfidence;
  final String? mealType;
  final bool isCustom;
  final String? source;
  final String? notes;

  FoodLog({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.foodName,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.portionSize,
    this.quantity,
    this.unit,
    this.imageUrl,
    this.aiConfidence,
    this.mealType,
    required this.isCustom,
    this.source,
    this.notes,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      userId: json['user_id'],
      loggedAt: DateTime.parse(json['logged_at']),
      foodName: json['food_name'],
      calories: json['calories'].toDouble(),
      proteinG: json['protein_g']?.toDouble(),
      carbsG: json['carbs_g']?.toDouble(),
      fatG: json['fat_g']?.toDouble(),
      fiberG: json['fiber_g']?.toDouble(),
      portionSize: json['portion_size'],
      quantity: json['quantity']?.toDouble(),
      unit: json['unit'],
      imageUrl: json['image_url'],
      aiConfidence: json['ai_confidence']?.toDouble(),
      mealType: json['meal_type'],
      isCustom: json['is_custom'],
      source: json['source'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'portion_size': portionSize,
      'quantity': quantity,
      'unit': unit,
      'image_url': imageUrl,
      'meal_type': mealType,
      'source': source,
      'notes': notes,
    };
  }
}

class WeightEntry {
  final int id;
  final int userId;
  final DateTime recordedAt;
  final double weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final double? hipsCm;
  final double? chestCm;
  final String? notes;

  WeightEntry({
    required this.id,
    required this.userId,
    required this.recordedAt,
    required this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.hipsCm,
    this.chestCm,
    this.notes,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'],
      userId: json['user_id'],
      recordedAt: DateTime.parse(json['recorded_at']),
      weightKg: json['weight_kg'].toDouble(),
      bodyFatPercent: json['body_fat_percent']?.toDouble(),
      waistCm: json['waist_cm']?.toDouble(),
      hipsCm: json['hips_cm']?.toDouble(),
      chestCm: json['chest_cm']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight_kg': weightKg,
      'body_fat_percent': bodyFatPercent,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'chest_cm': chestCm,
      'notes': notes,
    };
  }
}

class Activity {
  final int id;
  final int userId;
  final DateTime loggedAt;
  final String activityName;
  final String? activityType;
  final int durationMinutes;
  final String? intensity;
  final double? caloriesBurned;
  final double? distanceKm;
  final int? steps;
  final int? heartRateAvg;
  final String? source;
  final String? notes;

  Activity({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.activityName,
    this.activityType,
    required this.durationMinutes,
    this.intensity,
    this.caloriesBurned,
    this.distanceKm,
    this.steps,
    this.heartRateAvg,
    this.source,
    this.notes,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['user_id'],
      loggedAt: DateTime.parse(json['logged_at']),
      activityName: json['activity_name'],
      activityType: json['activity_type'],
      durationMinutes: json['duration_minutes'],
      intensity: json['intensity'],
      caloriesBurned: json['calories_burned']?.toDouble(),
      distanceKm: json['distance_km']?.toDouble(),
      steps: json['steps'],
      heartRateAvg: json['heart_rate_avg'],
      source: json['source'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_name': activityName,
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'calories_burned': caloriesBurned,
      'distance_km': distanceKm,
      'steps': steps,
      'heart_rate_avg': heartRateAvg,
      'source': source,
      'notes': notes,
    };
  }
}

class DiaryEntry {
  final int id;
  final int userId;
  final DateTime createdAt;
  final String? mood;
  final int? energyLevel;
  final int? hungerLevel;
  final double? sleepHours;
  final String? sleepQuality;
  final String? wins;
  final String? challenges;
  final String? proudOf;
  final String? notes;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.mood,
    this.energyLevel,
    this.hungerLevel,
    this.sleepHours,
    this.sleepQuality,
    this.wins,
    this.challenges,
    this.proudOf,
    this.notes,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      mood: json['mood'],
      energyLevel: json['energy_level'],
      hungerLevel: json['hunger_level'],
      sleepHours: json['sleep_hours']?.toDouble(),
      sleepQuality: json['sleep_quality'],
      wins: json['wins'],
      challenges: json['challenges'],
      proudOf: json['proud_of'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'energy_level': energyLevel,
      'hunger_level': hungerLevel,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'wins': wins,
      'challenges': challenges,
      'proud_of': proudOf,
      'notes': notes,
    };
  }
}
