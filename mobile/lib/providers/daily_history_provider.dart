import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyNutritionSummary {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const DailyNutritionSummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class DailyHistoryNotifier extends StateNotifier<List<DailyNutritionSummary>> {
  DailyHistoryNotifier() : super([]) {
    load();
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final results = <DailyNutritionSummary>[];

    for (int i = 29; i >= 1; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final json = prefs.getString('food_log_${_dateStr(date)}');
      if (json != null) {
        final entries = jsonDecode(json) as List;
        double cal = 0, pro = 0, car = 0, fat = 0;
        for (final e in entries) {
          cal += (e['calories'] as num).toDouble();
          pro += (e['protein'] as num).toDouble();
          car += (e['carbs'] as num).toDouble();
          fat += (e['fat'] as num).toDouble();
        }
        if (cal > 0) {
          results.add(DailyNutritionSummary(
            date: date,
            calories: cal,
            protein: pro,
            carbs: car,
            fat: fat,
          ));
        }
      }
    }

    state = results;
  }
}

final dailyHistoryProvider =
    StateNotifierProvider<DailyHistoryNotifier, List<DailyNutritionSummary>>(
  (ref) => DailyHistoryNotifier(),
);
