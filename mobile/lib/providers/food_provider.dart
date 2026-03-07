import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_provider.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'meal': meal.name,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: j['id'],
        name: j['name'],
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        servingSize: (j['servingSize'] as num).toDouble(),
        servingUnit: j['servingUnit'],
        meal: MealType.values.firstWhere(
          (m) => m.name == j['meal'],
          orElse: () => MealType.snack,
        ),
        loggedAt: DateTime.parse(j['loggedAt']),
      );
}

class MealTemplate {
  final String id;
  final String name;
  final List<Map<String, dynamic>> items; // simplified food data

  const MealTemplate({required this.id, required this.name, required this.items});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'items': items};

  factory MealTemplate.fromJson(Map<String, dynamic> j) => MealTemplate(
        id: j['id'],
        name: j['name'],
        items: List<Map<String, dynamic>>.from(j['items']),
      );
}

class FoodLogState {
  final List<FoodEntry> entries;
  final double dailyCalorieGoal;
  final List<MealTemplate> templates;

  const FoodLogState({
    this.entries = const [],
    this.dailyCalorieGoal = 2000,
    this.templates = const [],
  });

  double get totalCalories => entries.fold(0, (s, e) => s + e.calories);
  double get totalProtein => entries.fold(0, (s, e) => s + e.protein);
  double get totalCarbs => entries.fold(0, (s, e) => s + e.carbs);
  double get totalFat => entries.fold(0, (s, e) => s + e.fat);
  double get remainingCalories =>
      (dailyCalorieGoal - totalCalories).clamp(0, dailyCalorieGoal);

  List<FoodEntry> entriesForMeal(MealType meal) =>
      entries.where((e) => e.meal == meal).toList();

  FoodLogState copyWith({
    List<FoodEntry>? entries,
    double? dailyCalorieGoal,
    List<MealTemplate>? templates,
  }) =>
      FoodLogState(
        entries: entries ?? this.entries,
        dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
        templates: templates ?? this.templates,
      );
}

class FoodLogNotifier extends StateNotifier<FoodLogState>
    with WidgetsBindingObserver {
  final Ref _ref;
  String _loadedDate = '';

  FoodLogNotifier(this._ref) : super(const FoodLogState()) {
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

  String get _todayKey => 'food_log_${_todayDateStr()}';

  Future<void> _load() async {
    _loadedDate = _todayDateStr();
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getDouble('calorie_goal') ?? 2000;
    final json = prefs.getString(_todayKey);
    final templateJson = prefs.getString('meal_templates');
    final entries = json != null
        ? (jsonDecode(json) as List).map((e) => FoodEntry.fromJson(e)).toList()
        : <FoodEntry>[];
    final templates = templateJson != null
        ? (jsonDecode(templateJson) as List)
            .map((t) => MealTemplate.fromJson(t))
            .toList()
        : <MealTemplate>[];
    state = FoodLogState(entries: entries, dailyCalorieGoal: goal, templates: templates);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _todayKey,
      jsonEncode(state.entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'meal_templates',
      jsonEncode(state.templates.map((t) => t.toJson()).toList()),
    );
  }

  void addEntry(FoodEntry entry) {
    state = state.copyWith(entries: [...state.entries, entry]);
    _save();
    _ref.read(streakProvider.notifier).onFoodLogged();
  }

  void removeEntry(String id) {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
    _save();
  }

  void updateEntry(FoodEntry updated) {
    state = state.copyWith(
      entries: state.entries.map((e) => e.id == updated.id ? updated : e).toList(),
    );
    _save();
  }

  void saveAsTemplate(String name, List<FoodEntry> entries) {
    final template = MealTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: entries
          .map((e) => {
                'name': e.name,
                'calories': e.calories,
                'protein': e.protein,
                'carbs': e.carbs,
                'fat': e.fat,
                'servingSize': e.servingSize,
                'servingUnit': e.servingUnit,
              })
          .toList(),
    );
    state = state.copyWith(templates: [...state.templates, template]);
    _saveTemplates();
  }

  void applyTemplate(MealTemplate template, MealType mealType) {
    final now = DateTime.now();
    final newEntries = template.items.map((item) {
      return FoodEntry(
        id: '${now.millisecondsSinceEpoch}_${item['name']}',
        name: item['name'] as String,
        calories: (item['calories'] as num).toDouble(),
        protein: (item['protein'] as num).toDouble(),
        carbs: (item['carbs'] as num).toDouble(),
        fat: (item['fat'] as num).toDouble(),
        servingSize: (item['servingSize'] as num).toDouble(),
        servingUnit: item['servingUnit'] as String,
        meal: mealType,
        loggedAt: now,
      );
    }).toList();
    state = state.copyWith(entries: [...state.entries, ...newEntries]);
    _save();
    _ref.read(streakProvider.notifier).onFoodLogged();
  }

  void deleteTemplate(String id) {
    state = state.copyWith(
      templates: state.templates.where((t) => t.id != id).toList(),
    );
    _saveTemplates();
  }

  void setCalorieGoal(double goal) {
    state = state.copyWith(dailyCalorieGoal: goal);
    SharedPreferences.getInstance()
        .then((p) => p.setDouble('calorie_goal', goal));
  }
}

final foodLogProvider =
    StateNotifierProvider<FoodLogNotifier, FoodLogState>((ref) {
  return FoodLogNotifier(ref);
});
