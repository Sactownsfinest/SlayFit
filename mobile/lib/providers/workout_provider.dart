import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class WorkoutSet {
  final int reps;
  final double? weightKg;

  const WorkoutSet({required this.reps, this.weightKg});

  WorkoutSet copyWith({int? reps, double? weightKg}) =>
      WorkoutSet(reps: reps ?? this.reps, weightKg: weightKg ?? this.weightKg);

  Map<String, dynamic> toJson() => {'reps': reps, 'weightKg': weightKg};

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        reps: (j['reps'] as num).toInt(),
        weightKg:
            j['weightKg'] != null ? (j['weightKg'] as num).toDouble() : null,
      );
}

class WorkoutExercise {
  final String id;
  final String name;
  final List<WorkoutSet> sets;

  const WorkoutExercise(
      {required this.id, required this.name, required this.sets});

  WorkoutExercise copyWith({String? name, List<WorkoutSet>? sets}) =>
      WorkoutExercise(
          id: id, name: name ?? this.name, sets: sets ?? this.sets);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
        id: j['id'] as String,
        name: j['name'] as String,
        sets: (j['sets'] as List)
            .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutPlan {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
        id: j['id'] as String,
        name: j['name'] as String,
        exercises: (j['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class WorkoutSession {
  final String id;
  final String planId;
  final String planName;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  final int durationMinutes;

  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.date,
    required this.exercises,
    required this.durationMinutes,
  });

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'planName': planName,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'durationMinutes': durationMinutes,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id'] as String,
        planId: j['planId'] as String,
        planName: j['planName'] as String,
        date: DateTime.parse(j['date'] as String),
        exercises: (j['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMinutes: j['durationMinutes'] as int,
      );
}

// ── State ──────────────────────────────────────────────────────────────────

class WorkoutState {
  final List<WorkoutPlan> plans;
  final List<WorkoutSession> history;

  const WorkoutState({this.plans = const [], this.history = const []});

  WorkoutState copyWith(
          {List<WorkoutPlan>? plans, List<WorkoutSession>? history}) =>
      WorkoutState(
          plans: plans ?? this.plans, history: history ?? this.history);

  List<WorkoutSession> get recentSessions {
    final sorted = [...history]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  List<WorkoutSession> get todaySessions {
    final now = DateTime.now();
    return history
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .toList();
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier() : super(const WorkoutState()) {
    _load();
  }

  static const _plansKey = 'workout_plans_v1';
  static const _historyKey = 'workout_sessions_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final plans = _decode<WorkoutPlan>(
          prefs.getString(_plansKey), WorkoutPlan.fromJson);
      final history = _decode<WorkoutSession>(
          prefs.getString(_historyKey), WorkoutSession.fromJson);
      state = WorkoutState(plans: plans, history: history);
    } catch (_) {}
  }

  List<T> _decode<T>(
      String? json, T Function(Map<String, dynamic>) fromJson) {
    if (json == null) return [];
    return (jsonDecode(json) as List)
        .map((j) => fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _plansKey, jsonEncode(state.plans.map((p) => p.toJson()).toList()));
    await prefs.setString(_historyKey,
        jsonEncode(state.history.map((s) => s.toJson()).toList()));
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> savePlan(WorkoutPlan plan) async {
    final plans = [...state.plans];
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      plans[idx] = plan;
    } else {
      plans.add(plan);
    }
    state = state.copyWith(plans: plans);
    await _save();
  }

  Future<void> deletePlan(String planId) async {
    state = state.copyWith(
        plans: state.plans.where((p) => p.id != planId).toList());
    await _save();
  }

  Future<void> logSession(WorkoutSession session) async {
    state = state.copyWith(history: [...state.history, session]);
    await _save();
  }

  WorkoutPlan newPlan(String name) => WorkoutPlan(
      id: _id(), name: name, exercises: [], createdAt: DateTime.now());

  WorkoutExercise newExercise(String name, int sets, int reps,
          {double? weightKg}) =>
      WorkoutExercise(
          id: _id(),
          name: name,
          sets: List.generate(
              sets, (_) => WorkoutSet(reps: reps, weightKg: weightKg)));

  WorkoutSession newSession(
          WorkoutPlan plan, List<WorkoutExercise> exercises, int duration) =>
      WorkoutSession(
          id: _id(),
          planId: plan.id,
          planName: plan.name,
          date: DateTime.now(),
          exercises: exercises,
          durationMinutes: duration);
}

final workoutProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier();
});
