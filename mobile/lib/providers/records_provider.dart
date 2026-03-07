import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class PersonalRecord {
  final String exerciseName;
  final int maxReps;
  final double? maxWeightKg;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.maxReps,
    this.maxWeightKg,
    required this.achievedAt,
  });
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class RecordsNotifier extends StateNotifier<List<PersonalRecord>> {
  RecordsNotifier(List<WorkoutSession> history) : super([]) {
    _computeFromHistory(history);
  }

  void updateHistory(List<WorkoutSession> history) {
    _computeFromHistory(history);
  }

  void _computeFromHistory(List<WorkoutSession> history) {
    final Map<String, PersonalRecord> best = {};

    for (final session in history) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          final name = exercise.name;
          final existing = best[name];
          final weight = set.weightKg;
          final reps = set.reps;

          final isBetter = existing == null ||
              (weight != null &&
                  (existing.maxWeightKg == null ||
                      weight > existing.maxWeightKg!)) ||
              (weight == null &&
                  existing.maxWeightKg == null &&
                  reps > existing.maxReps);

          if (isBetter) {
            best[name] = PersonalRecord(
              exerciseName: name,
              maxReps: reps,
              maxWeightKg: weight,
              achievedAt: session.date,
            );
          }
        }
      }
    }

    state = best.values.toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
  }

  // Returns true if this set is a new PR for the exercise
  bool checkAndUpdate(
      String exerciseName, int reps, double? weightKg, DateTime date) {
    final existing = state.where((r) => r.exerciseName == exerciseName).firstOrNull;

    final isBetter = existing == null ||
        (weightKg != null &&
            (existing.maxWeightKg == null || weightKg > existing.maxWeightKg!)) ||
        (weightKg == null &&
            existing.maxWeightKg == null &&
            reps > existing.maxReps);

    if (isBetter) {
      final updated = state
          .where((r) => r.exerciseName != exerciseName)
          .toList()
        ..add(PersonalRecord(
          exerciseName: exerciseName,
          maxReps: reps,
          maxWeightKg: weightKg,
          achievedAt: date,
        ));
      state = updated;
      return existing != null; // only "new PR" if something existed before
    }
    return false;
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final recordsProvider =
    StateNotifierProvider<RecordsNotifier, List<PersonalRecord>>((ref) {
  final history = ref.watch(workoutProvider).history;
  final notifier = RecordsNotifier(history);
  ref.listen(workoutProvider, (_, next) {
    notifier.updateHistory(next.history);
  });
  return notifier;
});
