import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class WeightState {
  final List<WeightEntry> entries;
  final double? goalWeightKg;

  const WeightState({
    this.entries = const [],
    this.goalWeightKg,
  });

  WeightEntry? get latest =>
      entries.isEmpty ? null : entries.last;

  double? get startWeight =>
      entries.isEmpty ? null : entries.first.weightKg;

  double? get totalLost {
    if (entries.length < 2) return null;
    return entries.first.weightKg - entries.last.weightKg;
  }

  WeightState copyWith({
    List<WeightEntry>? entries,
    double? goalWeightKg,
  }) {
    return WeightState(
      entries: entries ?? this.entries,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
    );
  }
}

class WeightNotifier extends StateNotifier<WeightState> {
  WeightNotifier()
      : super(WeightState(
          entries: _sampleEntries(),
        ));

  static List<WeightEntry> _sampleEntries() {
    final now = DateTime.now();
    return List.generate(14, (i) {
      return WeightEntry(
        id: 'sample_$i',
        weightKg: 85.0 - (i * 0.3) + (i % 3 == 0 ? 0.2 : 0),
        date: now.subtract(Duration(days: 13 - i)),
      );
    });
  }

  void logWeight(double weightKg, {String? note}) {
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weightKg: weightKg,
      date: DateTime.now(),
      note: note,
    );
    final updated = [...state.entries, entry];
    updated.sort((a, b) => a.date.compareTo(b.date));
    state = state.copyWith(entries: updated);
  }

  void setGoal(double goalKg) {
    state = state.copyWith(goalWeightKg: goalKg);
  }
}

final weightProvider =
    StateNotifierProvider<WeightNotifier, WeightState>((ref) {
  return WeightNotifier();
});
