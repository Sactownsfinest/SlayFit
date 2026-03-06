import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ActivityCategory { cardio, strength, flexibility, sports, other }

class ActivityEntry {
  final String id;
  final String name;
  final ActivityCategory category;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime loggedAt;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.loggedAt,
  });
}

class ActivityState {
  final List<ActivityEntry> entries;

  const ActivityState({this.entries = const []});

  double get todayCaloriesBurned {
    final today = DateTime.now();
    return entries
        .where((e) =>
            e.loggedAt.year == today.year &&
            e.loggedAt.month == today.month &&
            e.loggedAt.day == today.day)
        .fold(0, (sum, e) => sum + e.caloriesBurned);
  }

  int get todayMinutes {
    final today = DateTime.now();
    return entries
        .where((e) =>
            e.loggedAt.year == today.year &&
            e.loggedAt.month == today.month &&
            e.loggedAt.day == today.day)
        .fold(0, (sum, e) => sum + e.durationMinutes);
  }

  List<ActivityEntry> get todayEntries {
    final today = DateTime.now();
    return entries
        .where((e) =>
            e.loggedAt.year == today.year &&
            e.loggedAt.month == today.month &&
            e.loggedAt.day == today.day)
        .toList();
  }

  ActivityState copyWith({List<ActivityEntry>? entries}) {
    return ActivityState(entries: entries ?? this.entries);
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(const ActivityState());

  void logActivity({
    required String name,
    required ActivityCategory category,
    required int durationMinutes,
    required double caloriesBurned,
  }) {
    final entry = ActivityEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      loggedAt: DateTime.now(),
    );
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  void removeEntry(String id) {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier();
});

// Common activities with estimated calories/min
const List<Map<String, dynamic>> kCommonActivities = [
  {'name': 'Running', 'category': ActivityCategory.cardio, 'calsPerMin': 10.0},
  {'name': 'Walking', 'category': ActivityCategory.cardio, 'calsPerMin': 4.0},
  {'name': 'Cycling', 'category': ActivityCategory.cardio, 'calsPerMin': 8.0},
  {'name': 'Swimming', 'category': ActivityCategory.cardio, 'calsPerMin': 9.0},
  {'name': 'Jump Rope', 'category': ActivityCategory.cardio, 'calsPerMin': 12.0},
  {'name': 'Weight Training', 'category': ActivityCategory.strength, 'calsPerMin': 6.0},
  {'name': 'Push-ups', 'category': ActivityCategory.strength, 'calsPerMin': 5.0},
  {'name': 'Yoga', 'category': ActivityCategory.flexibility, 'calsPerMin': 3.0},
  {'name': 'Pilates', 'category': ActivityCategory.flexibility, 'calsPerMin': 4.0},
  {'name': 'Basketball', 'category': ActivityCategory.sports, 'calsPerMin': 8.0},
  {'name': 'Soccer', 'category': ActivityCategory.sports, 'calsPerMin': 9.0},
  {'name': 'HIIT', 'category': ActivityCategory.cardio, 'calsPerMin': 14.0},
];
