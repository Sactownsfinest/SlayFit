import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_provider.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class RecipeIngredient {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double amountG;
  final String unit;

  const RecipeIngredient({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.amountG,
    this.unit = 'g',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'amountG': amountG,
        'unit': unit,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        name: j['name'] as String,
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        amountG: (j['amountG'] as num).toDouble(),
        unit: j['unit'] as String? ?? 'g',
      );
}

class Recipe {
  final String id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    this.servings = 1,
    required this.ingredients,
  });

  double get totalCalories =>
      ingredients.fold(0, (s, i) => s + i.calories);
  double get totalProtein =>
      ingredients.fold(0, (s, i) => s + i.protein);
  double get totalCarbs =>
      ingredients.fold(0, (s, i) => s + i.carbs);
  double get totalFat =>
      ingredients.fold(0, (s, i) => s + i.fat);

  double get caloriesPerServing => totalCalories / servings;
  double get proteinPerServing => totalProtein / servings;
  double get carbsPerServing => totalCarbs / servings;
  double get fatPerServing => totalFat / servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servings': servings,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        name: j['name'] as String,
        servings: (j['servings'] as num?)?.toInt() ?? 1,
        ingredients: (j['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── State ────────────────────────────────────────────────────────────────────

class RecipeState {
  final List<Recipe> recipes;
  const RecipeState({this.recipes = const []});

  RecipeState copyWith({List<Recipe>? recipes}) =>
      RecipeState(recipes: recipes ?? this.recipes);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class RecipeNotifier extends StateNotifier<RecipeState> {
  final Ref _ref;
  RecipeNotifier(this._ref) : super(const RecipeState()) {
    _load();
  }

  static const _key = 'recipes_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    state = state.copyWith(recipes: list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.recipes.map((r) => r.toJson()).toList()));
  }

  Future<void> saveRecipe(Recipe recipe) async {
    final existing = state.recipes.indexWhere((r) => r.id == recipe.id);
    List<Recipe> updated;
    if (existing >= 0) {
      updated = [...state.recipes];
      updated[existing] = recipe;
    } else {
      updated = [recipe, ...state.recipes];
    }
    state = state.copyWith(recipes: updated);
    await _save();
  }

  Future<void> deleteRecipe(String id) async {
    state =
        state.copyWith(recipes: state.recipes.where((r) => r.id != id).toList());
    await _save();
  }

  Future<void> logRecipe(
      Recipe recipe, int servings, MealType mealType) async {
    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recipe.name,
      calories: recipe.caloriesPerServing * servings,
      protein: recipe.proteinPerServing * servings,
      carbs: recipe.carbsPerServing * servings,
      fat: recipe.fatPerServing * servings,
      servingSize: servings.toDouble(),
      servingUnit: 'serving',
      meal: mealType,
      loggedAt: DateTime.now(),
    );
    _ref.read(foodLogProvider.notifier).addEntry(entry);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final recipeProvider =
    StateNotifierProvider<RecipeNotifier, RecipeState>(
        (ref) => RecipeNotifier(ref));
