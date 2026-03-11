import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/claude_service.dart';

const kGroceryCategoryOrder = [
  'Produce',
  'Protein',
  'Dairy',
  'Grains',
  'Pantry',
  'Other',
];

// ── Models ────────────────────────────────────────────────────────────────────

class MealEntry {
  final String mealType;
  final String name;
  final String description;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final List<String> ingredients;
  final List<String> instructions;
  bool checked;

  MealEntry({
    required this.mealType,
    required this.name,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.ingredients,
    required this.instructions,
    this.checked = false,
  });

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
        mealType: j['type'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein'] as num?)?.toInt() ?? 0,
        carbsG: (j['carbs'] as num?)?.toInt() ?? 0,
        fatG: (j['fat'] as num?)?.toInt() ?? 0,
        ingredients: List<String>.from(j['ingredients'] as List? ?? []),
        instructions: List<String>.from(j['instructions'] as List? ?? []),
        checked: j['checked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'type': mealType,
        'name': name,
        'description': description,
        'calories': calories,
        'protein': proteinG,
        'carbs': carbsG,
        'fat': fatG,
        'ingredients': ingredients,
        'instructions': instructions,
        'checked': checked,
      };
}

class MealDay {
  final int day;
  final List<MealEntry> meals;
  MealDay({required this.day, required this.meals});
}

class GroceryItem {
  final String name;
  final String qty;
  final String category;
  bool checked;
  GroceryItem(
      {required this.name,
      required this.qty,
      required this.category,
      this.checked = false});
}

// ── State ─────────────────────────────────────────────────────────────────────

class MealPlanState {
  final List<MealDay> days;
  final List<GroceryItem> groceries;
  final String rawJson;
  final bool isGenerating;
  final String? error;

  const MealPlanState({
    this.days = const [],
    this.groceries = const [],
    this.rawJson = '',
    this.isGenerating = false,
    this.error,
  });

  bool get hasPlan => days.isNotEmpty;
  bool get hasGroceries => groceries.isNotEmpty;

  MealPlanState copyWith({
    List<MealDay>? days,
    List<GroceryItem>? groceries,
    String? rawJson,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) =>
      MealPlanState(
        days: days ?? this.days,
        groceries: groceries ?? this.groceries,
        rawJson: rawJson ?? this.rawJson,
        isGenerating: isGenerating ?? this.isGenerating,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MealPlanNotifier extends StateNotifier<MealPlanState> {
  MealPlanNotifier() : super(const MealPlanState()) {
    _load();
  }

  static const _keyFullPlan = 'meal_plan_full_v2';
  static const _keyGroceryChecked = 'meal_plan_grocery_checked_v2';
  static const _keyMealChecked = 'meal_plan_meal_checked_v2';

  static ({List<MealDay> days, List<GroceryItem> groceries}) _parse(
      Map<String, dynamic> json) {
    final daysJson = json['days'] as List? ?? [];
    final days = daysJson.map((d) {
      final mealsJson = d['meals'] as List? ?? [];
      return MealDay(
        day: (d['day'] as num?)?.toInt() ?? 0,
        meals: mealsJson
            .map((m) => MealEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
    }).toList();

    final groceriesJson = json['groceries'] as List? ?? [];
    final groceries = groceriesJson
        .map((g) {
          final m = g as Map<String, dynamic>;
          return GroceryItem(
            name: m['item'] as String? ?? m['name'] as String? ?? '',
            qty: m['qty'] as String? ?? '',
            category: m['category'] as String? ?? 'Other',
          );
        })
        .where((g) => g.name.isNotEmpty)
        .toList();

    return (days: days, groceries: groceries);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFullPlan) ?? '';
    if (raw.isEmpty) return;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = _parse(json);
      final days = parsed.days;
      final groceries = parsed.groceries;

      // Restore checked states
      final mealChecked = prefs.getString(_keyMealChecked) ?? '';
      if (mealChecked.isNotEmpty) {
        try {
          final matrix = jsonDecode(mealChecked) as List;
          for (int i = 0; i < matrix.length && i < days.length; i++) {
            final row = matrix[i] as List;
            for (int j = 0; j < row.length && j < days[i].meals.length; j++) {
              days[i].meals[j].checked = row[j] as bool? ?? false;
            }
          }
        } catch (_) {}
      }

      final groceryChecked = prefs.getString(_keyGroceryChecked) ?? '';
      if (groceryChecked.isNotEmpty) {
        try {
          final list = jsonDecode(groceryChecked) as List;
          for (int i = 0; i < list.length && i < groceries.length; i++) {
            groceries[i].checked = list[i] as bool? ?? false;
          }
        } catch (_) {}
      }

      if (mounted) {
        state = MealPlanState(days: days, groceries: groceries, rawJson: raw);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFullPlan, state.rawJson);
    await prefs.setString(
      _keyMealChecked,
      jsonEncode(state.days
          .map((d) => d.meals.map((m) => m.checked).toList())
          .toList()),
    );
    await prefs.setString(
      _keyGroceryChecked,
      jsonEncode(state.groceries.map((g) => g.checked).toList()),
    );
  }

  Future<void> generatePlan({
    required int calorieGoal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required String name,
    String? editRequest,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final result = await ClaudeService.generateFullPlan(
        calorieGoal: calorieGoal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        name: name,
        editRequest: editRequest,
        currentPlanJson: editRequest != null ? state.rawJson : null,
      );
      final rawJson = jsonEncode(result);
      final parsed = _parse(result);
      state = state.copyWith(
        days: parsed.days,
        groceries: parsed.groceries,
        rawJson: rawJson,
        isGenerating: false,
      );
      await _persist();
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Could not generate plan. Please try again.',
      );
    }
  }

  void toggleMealCheck(int dayIdx, int mealIdx, bool value) {
    if (dayIdx >= state.days.length) return;
    if (mealIdx >= state.days[dayIdx].meals.length) return;
    state.days[dayIdx].meals[mealIdx].checked = value;
    state = state.copyWith(days: List.from(state.days));
    _persist();
  }

  void toggleGrocery(int index, bool value) {
    if (index >= state.groceries.length) return;
    state.groceries[index].checked = value;
    state = state.copyWith(groceries: List.from(state.groceries));
    _persist();
  }
}

final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, MealPlanState>((ref) {
  return MealPlanNotifier();
});
