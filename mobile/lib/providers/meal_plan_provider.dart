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
  final String description;
  bool checked;
  MealEntry({required this.mealType, required this.description, this.checked = false});
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
  GroceryItem({required this.name, required this.qty, required this.category, this.checked = false});
}

// ── State ─────────────────────────────────────────────────────────────────────

class MealPlanState {
  final String rawMealPlan;
  final List<MealDay> days;
  final List<GroceryItem> groceries;
  final bool isGeneratingPlan;
  final bool isGeneratingGroceries;
  final String? error;

  const MealPlanState({
    this.rawMealPlan = '',
    this.days = const [],
    this.groceries = const [],
    this.isGeneratingPlan = false,
    this.isGeneratingGroceries = false,
    this.error,
  });

  bool get hasPlan => rawMealPlan.isNotEmpty && days.isNotEmpty;
  bool get hasGroceries => groceries.isNotEmpty;

  MealPlanState copyWith({
    String? rawMealPlan,
    List<MealDay>? days,
    List<GroceryItem>? groceries,
    bool? isGeneratingPlan,
    bool? isGeneratingGroceries,
    String? error,
    bool clearError = false,
  }) =>
      MealPlanState(
        rawMealPlan: rawMealPlan ?? this.rawMealPlan,
        days: days ?? this.days,
        groceries: groceries ?? this.groceries,
        isGeneratingPlan: isGeneratingPlan ?? this.isGeneratingPlan,
        isGeneratingGroceries: isGeneratingGroceries ?? this.isGeneratingGroceries,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MealPlanNotifier extends StateNotifier<MealPlanState> {
  MealPlanNotifier() : super(const MealPlanState()) {
    _load();
  }

  // Same keys as original grocery_list_screen.dart for backwards compatibility
  static const _keyRawPlan = 'grocery_raw_plan_v1';
  static const _keyItems = 'grocery_items_v1';
  static const _keyMealChecked = 'grocery_meal_checked_v1';

  static List<MealDay> parseMealPlan(String raw) {
    final days = <MealDay>[];
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    MealDay? current;
    final dayRx = RegExp(r'^Day\s+(\d+)', caseSensitive: false);
    final mealRx = RegExp(r'^(Breakfast|Lunch|Dinner|Snack)[:\s]+(.+)', caseSensitive: false);
    for (final line in lines) {
      final d = dayRx.firstMatch(line);
      if (d != null) {
        if (current != null) days.add(current);
        current = MealDay(day: int.tryParse(d.group(1) ?? '1') ?? 1, meals: []);
        continue;
      }
      final m = mealRx.firstMatch(line);
      if (m != null && current != null) {
        current.meals.add(MealEntry(mealType: m.group(1)!, description: m.group(2)!.trim()));
      }
    }
    if (current != null) days.add(current);
    return days;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRawPlan) ?? '';
    final itemsJson = prefs.getString(_keyItems) ?? '';
    if (raw.isEmpty && itemsJson.isEmpty) return;

    final days = raw.isNotEmpty ? parseMealPlan(raw) : <MealDay>[];

    final mealCheckedJson = prefs.getString(_keyMealChecked) ?? '';
    if (mealCheckedJson.isNotEmpty) {
      try {
        final matrix = jsonDecode(mealCheckedJson) as List;
        for (int i = 0; i < matrix.length && i < days.length; i++) {
          final row = matrix[i] as List;
          for (int j = 0; j < row.length && j < days[i].meals.length; j++) {
            days[i].meals[j].checked = row[j] as bool? ?? false;
          }
        }
      } catch (_) {}
    }

    final groceries = <GroceryItem>[];
    if (itemsJson.isNotEmpty) {
      try {
        final rawList = jsonDecode(itemsJson) as List;
        for (final e in rawList) {
          final m = e as Map<String, dynamic>;
          groceries.add(GroceryItem(
            name: m['name'] as String? ?? '',
            qty: m['qty'] as String? ?? '',
            category: m['category'] as String? ?? 'Other',
            checked: m['checked'] as bool? ?? false,
          ));
        }
      } catch (_) {}
    }

    if (mounted) {
      state = MealPlanState(rawMealPlan: raw, days: days, groceries: groceries);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRawPlan, state.rawMealPlan);
    await prefs.setString(
      _keyItems,
      jsonEncode(state.groceries
          .map((g) => {'name': g.name, 'qty': g.qty, 'category': g.category, 'checked': g.checked})
          .toList()),
    );
    await prefs.setString(
      _keyMealChecked,
      jsonEncode(state.days.map((d) => d.meals.map((m) => m.checked).toList()).toList()),
    );
  }

  Future<void> generatePlan({
    required int calorieGoal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required String name,
  }) async {
    state = state.copyWith(isGeneratingPlan: true, clearError: true);
    try {
      final raw = await ClaudeService.generateMealPlan(
        calorieGoal: calorieGoal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        name: name,
      );
      final days = parseMealPlan(raw);
      state = state.copyWith(rawMealPlan: raw, days: days, isGeneratingPlan: false);
      await _persist();
    } catch (_) {
      state = state.copyWith(
          isGeneratingPlan: false, error: 'Could not generate plan. Please try again.');
    }
  }

  Future<void> editPlan({
    required String editRequest,
    required int calorieGoal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required String name,
  }) async {
    state = state.copyWith(isGeneratingPlan: true, clearError: true);
    try {
      final raw = await ClaudeService.generateMealPlan(
        calorieGoal: calorieGoal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        name: name,
        editRequest: editRequest,
        currentPlan: state.rawMealPlan,
      );
      final days = parseMealPlan(raw);
      state = state.copyWith(rawMealPlan: raw, days: days, isGeneratingPlan: false);
      await _persist();
    } catch (_) {
      state = state.copyWith(
          isGeneratingPlan: false, error: 'Could not update plan. Please try again.');
    }
  }

  Future<void> generateGroceries({
    required int calorieGoal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required String name,
  }) async {
    state = state.copyWith(isGeneratingGroceries: true, clearError: true);
    try {
      final result = await ClaudeService.generateGroceryList(
        calorieGoal: calorieGoal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        name: name,
      );
      final mealPlan = result['mealPlan'] as String? ?? '';
      final rawList = result['groceries'] as List<dynamic>? ?? [];
      final groceries = rawList
          .map((e) {
            final m = e as Map<String, dynamic>;
            return GroceryItem(
              name: m['item'] as String? ?? '',
              qty: m['qty'] as String? ?? '',
              category: m['category'] as String? ?? 'Other',
            );
          })
          .where((i) => i.name.isNotEmpty)
          .toList();

      String rawPlanText = state.rawMealPlan;
      List<MealDay> days = state.days;
      if (mealPlan.isNotEmpty && rawPlanText.isEmpty) {
        rawPlanText = mealPlan;
        days = parseMealPlan(mealPlan);
      }
      state = state.copyWith(
        rawMealPlan: rawPlanText,
        days: days,
        groceries: groceries,
        isGeneratingGroceries: false,
      );
      await _persist();
    } catch (_) {
      state = state.copyWith(
          isGeneratingGroceries: false,
          error: 'Could not generate grocery list. Please try again.');
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

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, MealPlanState>((ref) {
  return MealPlanNotifier();
});
