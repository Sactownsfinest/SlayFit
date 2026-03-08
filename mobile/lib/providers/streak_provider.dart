import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({DateTime? unlockedAt}) => Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };
}

const List<Achievement> kAllAchievements = [
  Achievement(
    id: 'first_step',
    title: 'First Step',
    description: 'Log your first food entry',
    icon: Icons.emoji_food_beverage,
  ),
  Achievement(
    id: 'on_fire',
    title: 'On Fire',
    description: '7-day logging streak',
    icon: Icons.local_fire_department,
  ),
  Achievement(
    id: 'unstoppable',
    title: 'Unstoppable',
    description: '30-day logging streak',
    icon: Icons.bolt,
  ),
  Achievement(
    id: 'workout_warrior',
    title: 'Workout Warrior',
    description: 'Log 10 activities',
    icon: Icons.fitness_center,
  ),
  Achievement(
    id: 'calorie_counter',
    title: 'Calorie Counter',
    description: 'Log 50 food entries',
    icon: Icons.restaurant,
  ),
  Achievement(
    id: 'goal_crusher',
    title: 'Goal Crusher',
    description: 'Hit calorie goal 5 days in a row',
    icon: Icons.military_tech,
  ),
];

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final String? lastLoggedDate;
  final List<Achievement> achievements;
  final int totalFoodLogs;
  final int totalActivityLogs;
  final int goalHitStreak;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoggedDate,
    this.achievements = kAllAchievements,
    this.totalFoodLogs = 0,
    this.totalActivityLogs = 0,
    this.goalHitStreak = 0,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastLoggedDate,
    List<Achievement>? achievements,
    int? totalFoodLogs,
    int? totalActivityLogs,
    int? goalHitStreak,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastLoggedDate: lastLoggedDate ?? this.lastLoggedDate,
        achievements: achievements ?? this.achievements,
        totalFoodLogs: totalFoodLogs ?? this.totalFoodLogs,
        totalActivityLogs: totalActivityLogs ?? this.totalActivityLogs,
        goalHitStreak: goalHitStreak ?? this.goalHitStreak,
      );
}

class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(const StreakState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('streak_data');
    if (json == null) return;

    final data = jsonDecode(json) as Map<String, dynamic>;
    final unlockedMap = <String, DateTime?>{};
    final unlocked = data['unlocked_achievements'] as List? ?? [];
    for (final item in unlocked) {
      unlockedMap[item['id']] = item['unlockedAt'] != null
          ? DateTime.parse(item['unlockedAt'])
          : null;
    }

    final achievements = kAllAchievements.map((a) {
      if (unlockedMap.containsKey(a.id)) {
        return a.copyWith(unlockedAt: unlockedMap[a.id] ?? DateTime.now());
      }
      return a;
    }).toList();

    state = StreakState(
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastLoggedDate: data['lastLoggedDate'],
      achievements: achievements,
      totalFoodLogs: data['totalFoodLogs'] ?? 0,
      totalActivityLogs: data['totalActivityLogs'] ?? 0,
      goalHitStreak: data['goalHitStreak'] ?? 0,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedAchievements = state.achievements
        .where((a) => a.isUnlocked)
        .map((a) => {'id': a.id, 'unlockedAt': a.unlockedAt?.toIso8601String()})
        .toList();

    final encoded = jsonEncode({
      'currentStreak': state.currentStreak,
      'longestStreak': state.longestStreak,
      'lastLoggedDate': state.lastLoggedDate,
      'unlocked_achievements': unlockedAchievements,
      'totalFoodLogs': state.totalFoodLogs,
      'totalActivityLogs': state.totalActivityLogs,
      'goalHitStreak': state.goalHitStreak,
    });
    await prefs.setString('streak_data', encoded);
    CloudSyncService.upload('streak_data', encoded);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> resetAchievements() async {
    state = state.copyWith(
      achievements: kAllAchievements.map((a) => a.copyWith(unlockedAt: null)).toList(),
    );
    await _save();
  }

  Future<void> onFoodLogged() async {
    final newTotal = state.totalFoodLogs + 1;
    state = state.copyWith(totalFoodLogs: newTotal);
    await _updateStreak();
    await _checkAchievements();
    await _save();
  }

  Future<void> onActivityLogged() async {
    final newTotal = state.totalActivityLogs + 1;
    state = state.copyWith(totalActivityLogs: newTotal);
    await _updateStreak();
    await _checkAchievements();
    await _save();
  }

  Future<void> onGoalHit() async {
    final newStreak = state.goalHitStreak + 1;
    state = state.copyWith(goalHitStreak: newStreak);
    await _checkAchievements();
    await _save();
  }

  Future<void> _updateStreak() async {
    final today = _todayStr();
    if (state.lastLoggedDate == today) return;

    int newStreak = state.currentStreak;
    if (state.lastLoggedDate != null) {
      final last = DateTime.parse(state.lastLoggedDate!);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > state.longestStreak ? newStreak : state.longestStreak;

    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastLoggedDate: today,
    );
  }

  Future<void> _checkAchievements() async {
    final now = DateTime.now();
    var achievements = List<Achievement>.from(state.achievements);
    bool changed = false;

    void unlock(String id) {
      final idx = achievements.indexWhere((a) => a.id == id && !a.isUnlocked);
      if (idx != -1) {
        achievements[idx] = achievements[idx].copyWith(unlockedAt: now);
        changed = true;
      }
    }

    if (state.totalFoodLogs >= 1) unlock('first_step');
    if (state.currentStreak >= 7) unlock('on_fire');
    if (state.currentStreak >= 30) unlock('unstoppable');
    if (state.totalActivityLogs >= 10) unlock('workout_warrior');
    if (state.totalFoodLogs >= 50) unlock('calorie_counter');
    if (state.goalHitStreak >= 5) unlock('goal_crusher');

    if (changed) {
      state = state.copyWith(achievements: achievements);
    }
  }
}

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});
