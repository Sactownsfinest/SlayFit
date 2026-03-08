import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_provider.dart';
import '../services/cloud_sync_service.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
        id: j['id'],
        name: j['name'],
        category: ActivityCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => ActivityCategory.other,
        ),
        durationMinutes: j['durationMinutes'],
        caloriesBurned: (j['caloriesBurned'] as num).toDouble(),
        loggedAt: DateTime.parse(j['loggedAt']),
      );
}

class ActivityState {
  final List<ActivityEntry> entries;

  const ActivityState({this.entries = const []});

  List<ActivityEntry> get todayEntries {
    final today = DateTime.now();
    return entries
        .where((e) =>
            e.loggedAt.year == today.year &&
            e.loggedAt.month == today.month &&
            e.loggedAt.day == today.day)
        .toList();
  }

  double get todayCaloriesBurned =>
      todayEntries.fold(0, (s, e) => s + e.caloriesBurned);

  int get todayMinutes =>
      todayEntries.fold(0, (s, e) => s + e.durationMinutes);

  ActivityState copyWith({List<ActivityEntry>? entries}) =>
      ActivityState(entries: entries ?? this.entries);
}

class ActivityNotifier extends StateNotifier<ActivityState>
    with WidgetsBindingObserver {
  final Ref _ref;
  String _loadedDate = '';

  ActivityNotifier(this._ref) : super(const ActivityState()) {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _todayDateStr() != _loadedDate) {
      _load();
    }
  }

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _todayKey => 'activity_log_${_todayDateStr()}';

  Future<void> _load() async {
    _loadedDate = _todayDateStr();
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_todayKey);
    if (json != null) {
      final List list = jsonDecode(json);
      final entries = list.map((e) => ActivityEntry.fromJson(e)).toList();
      state = ActivityState(entries: entries);
    } else {
      state = const ActivityState();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.entries.map((e) => e.toJson()).toList());
    await prefs.setString(_todayKey, encoded);
    CloudSyncService.upload(_todayKey, encoded);
  }

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
    _save();
    _ref.read(streakProvider.notifier).onActivityLogged();
  }

  void removeEntry(String id) {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
    _save();
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier(ref);
});

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
