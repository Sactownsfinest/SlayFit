import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';

class WaterEntry {
  final String id;
  final int amountMl;
  final DateTime loggedAt;

  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMl': amountMl,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory WaterEntry.fromJson(Map<String, dynamic> j) => WaterEntry(
        id: j['id'],
        amountMl: j['amountMl'],
        loggedAt: DateTime.parse(j['loggedAt']),
      );
}

class WaterState {
  final List<WaterEntry> entries;
  final int dailyGoalMl;

  const WaterState({this.entries = const [], this.dailyGoalMl = 1893}); // 64 oz default

  List<WaterEntry> get todayEntries {
    final today = DateTime.now();
    return entries
        .where((e) =>
            e.loggedAt.year == today.year &&
            e.loggedAt.month == today.month &&
            e.loggedAt.day == today.day)
        .toList();
  }

  int get todayTotalMl => todayEntries.fold(0, (s, e) => s + e.amountMl);

  double get todayProgressPercent =>
      (todayTotalMl / dailyGoalMl).clamp(0.0, 1.0);

  WaterState copyWith({List<WaterEntry>? entries, int? dailyGoalMl}) =>
      WaterState(
        entries: entries ?? this.entries,
        dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      );
}

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier() : super(const WaterState()) {
    _load();
  }

  String _todayKey() {
    final now = DateTime.now();
    return 'water_log_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goalMl = prefs.getInt('water_goal_ml') ?? 1893; // 64 oz default
    final json = prefs.getString(_todayKey());
    final entries = json != null
        ? (jsonDecode(json) as List)
            .map((e) => WaterEntry.fromJson(e))
            .toList()
        : <WaterEntry>[];
    state = WaterState(entries: entries, dailyGoalMl: goalMl);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final todayEntries = state.todayEntries;
    final key = _todayKey();
    final encoded = jsonEncode(todayEntries.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
    CloudSyncService.upload(key, encoded);
  }

  Future<void> addWater(int amountMl) async {
    final entry = WaterEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    );
    state = state.copyWith(entries: [...state.entries, entry]);
    await _save();
  }

  Future<void> removeEntry(String id) async {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
    await _save();
  }

  Future<void> setGoal(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal_ml', goalMl);
    state = state.copyWith(dailyGoalMl: goalMl);
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier();
});
