import 'dart:convert';
import 'package:http/http.dart' as http;

const _kGroqApiKey = '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';
const _kModel = 'llama-3.3-70b-versatile';

class AiExercise {
  final String name;
  final int sets;
  final int reps;
  final int restSeconds;

  const AiExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  factory AiExercise.fromJson(Map<String, dynamic> j) => AiExercise(
        name: j['name'] as String,
        sets: (j['sets'] as num).toInt(),
        reps: (j['reps'] as num).toInt(),
        restSeconds: (j['rest'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'sets': sets, 'reps': reps, 'rest': restSeconds};
}

class AiWorkoutPlan {
  final String name;
  final String focus;
  final int durationMinutes;
  final List<AiExercise> exercises;
  final int estimatedCalories;
  final String youtubeQuery;
  final DateTime generatedAt;

  const AiWorkoutPlan({
    required this.name,
    required this.focus,
    required this.durationMinutes,
    required this.exercises,
    required this.estimatedCalories,
    required this.youtubeQuery,
    required this.generatedAt,
  });

  factory AiWorkoutPlan.fromJson(Map<String, dynamic> j) => AiWorkoutPlan(
        name: j['name'] as String,
        focus: j['focus'] as String,
        durationMinutes: (j['durationMinutes'] as num).toInt(),
        exercises: (j['exercises'] as List)
            .map((e) => AiExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        estimatedCalories: (j['estimatedCalories'] as num).toInt(),
        youtubeQuery: j['youtubeQuery'] as String,
        generatedAt: DateTime.parse(j['generatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'focus': focus,
        'durationMinutes': durationMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'estimatedCalories': estimatedCalories,
        'youtubeQuery': youtubeQuery,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class WorkoutAiService {
  static Future<AiWorkoutPlan> generatePlan({
    required String userName,
    required double? currentWeightKg,
    required double? goalWeightKg,
    required int dailyCalorieGoal,
  }) async {
    final lbs = currentWeightKg != null
        ? '${(currentWeightKg * 2.20462).toStringAsFixed(1)} lbs'
        : null;
    final goalLbs = goalWeightKg != null
        ? '${(goalWeightKg * 2.20462).toStringAsFixed(1)} lbs'
        : null;

    final weightLine = lbs != null
        ? 'Current weight: $lbs${goalLbs != null ? ", goal: $goalLbs" : ""}.'
        : '';
    final isWeightLoss = currentWeightKg != null &&
        goalWeightKg != null &&
        goalWeightKg < currentWeightKg;

    final prompt =
        'Create a personalized home workout plan for $userName. $weightLine Daily calorie goal: $dailyCalorieGoal kcal. Focus: ${isWeightLoss ? "fat burn and cardio" : "strength and fitness"}.\n\n'
        'Respond with ONLY a valid JSON object, no markdown, no extra text:\n'
        '{"name":"Short plan name","focus":"Fat Burn","durationMinutes":30,"exercises":[{"name":"Exercise","sets":3,"reps":12,"rest":30}],"estimatedCalories":250,"youtubeQuery":"30 minute fat burn HIIT beginner home no equipment"}\n\n'
        'Rules: 5-8 exercises for home use, no gym equipment. durationMinutes must be 20, 30, or 45. youtubeQuery must exactly match the workout type and duration shown in exercises.';

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_kGroqApiKey',
          },
          body: jsonEncode({
            'model': _kModel,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 600,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('api_error_${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['choices'][0]['message']['content'] as String;

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) throw Exception('Invalid AI response format');

    final planJson =
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    return AiWorkoutPlan.fromJson(
        {...planJson, 'generatedAt': DateTime.now().toIso8601String()});
  }
}
