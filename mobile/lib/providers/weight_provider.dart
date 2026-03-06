import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightEntry {
  final String id;
  final double weightKg;
  final DateTime date;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'date': date.toIso8601String(),
        if (note != null) 'note': note,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        id: j['id'],
        weightKg: (j['weightKg'] as num).toDouble(),
        date: DateTime.parse(j['date']),
        note: j['note'],
      );
}

class WeightState {
  final List<WeightEntry> entries;
  final double? goalWeightKg;

  const WeightState({
    this.entries = const [],
    this.goalWeightKg,
  });

  WeightEntry? get latest => entries.isEmpty ? null : entries.last;
  double? get startWeight => entries.isEmpty ? null : entries.first.weightKg;

  double? get totalLost {
    if (entries.length < 2) return null;
    return entries.first.weightKg - entries.last.weightKg;
  }

  WeightState copyWith({List<WeightEntry>? entries, double? goalWeightKg}) =>
      WeightState(
        entries: entries ?? this.entries,
        goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      );
}

class WeightNotifier extends StateNotifier<WeightState> {
  WeightNotifier() : super(const WeightState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('weight_history');
    final goalKg = prefs.getDouble('goal_weight_kg');
    if (json != null) {
      final List list = jsonDecode(json);
      final entries = list.map((e) => WeightEntry.fromJson(e)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      state = WeightState(entries: entries, goalWeightKg: goalKg);
    } else {
      state = WeightState(goalWeightKg: goalKg);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'weight_history',
      jsonEncode(state.entries.map((e) => e.toJson()).toList()),
    );
  }

  void logWeight(double weightKg, {String? note}) {
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weightKg: weightKg,
      date: DateTime.now(),
      note: note,
    );
    final updated = [...state.entries, entry]
      ..sort((a, b) => a.date.compareTo(b.date));
    state = state.copyWith(entries: updated);
    _save();
  }

  void setGoal(double goalKg) {
    state = state.copyWith(goalWeightKg: goalKg);
    SharedPreferences.getInstance()
        .then((p) => p.setDouble('goal_weight_kg', goalKg));
  }
}

final weightProvider =
    StateNotifierProvider<WeightNotifier, WeightState>((ref) {
  return WeightNotifier();
});
