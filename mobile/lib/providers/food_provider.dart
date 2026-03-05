import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MealType { breakfast, lunch, dinner, snack }

class FoodEntry {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final MealType meal;
  final DateTime loggedAt;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    required this.meal,
    required this.loggedAt,
  });
}

class FoodLogState {
  final List<FoodEntry> entries;
  final double dailyCalorieGoal;

  const FoodLogState({
    this.entries = const [],
    this.dailyCalorieGoal = 2000,
  });

  double get totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein =>
      entries.fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs =>
      entries.fold(0, (sum, e) => sum + e.carbs);
  double get totalFat =>
      entries.fold(0, (sum, e) => sum + e.fat);
  double get remainingCalories =>
      (dailyCalorieGoal - totalCalories).clamp(0, dailyCalorieGoal);

  List<FoodEntry> entriesForMeal(MealType meal) =>
      entries.where((e) => e.meal == meal).toList();

  FoodLogState copyWith({
    List<FoodEntry>? entries,
    double? dailyCalorieGoal,
  }) {
    return FoodLogState(
      entries: entries ?? this.entries,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }
}

class FoodLogNotifier extends StateNotifier<FoodLogState> {
  FoodLogNotifier() : super(const FoodLogState());

  void addEntry(FoodEntry entry) {
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  void removeEntry(String id) {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }

  void setCalorieGoal(double goal) {
    state = state.copyWith(dailyCalorieGoal: goal);
  }
}

final foodLogProvider =
    StateNotifierProvider<FoodLogNotifier, FoodLogState>((ref) {
  return FoodLogNotifier();
});
