import 'dart:convert';
import 'package:http/http.dart' as http;

const _kGeminiApiKey = 'AIzaSyAw1iPUeIaQumZ8o0ANW_qQtPS3O3DU7A0';
const _kModel = 'gemini-2.0-flash-lite';

class ClaudeService {
  static String _buildSystemPrompt(Map<String, dynamic> ctx) {
    final calories = ctx['calories'] ?? 0;
    final calorieGoal = ctx['calorieGoal'] ?? 2000;
    final proteinG = ctx['proteinG'] ?? 0;
    final carbsG = ctx['carbsG'] ?? 0;
    final fatG = ctx['fatG'] ?? 0;
    final waterMl = ctx['waterMl'] ?? 0;
    final streak = ctx['streak'] ?? 0;
    final name = ctx['name'] ?? 'User';
    final currentWeight = ctx['currentWeight'] as double?;
    final goalWeight = ctx['goalWeight'] as double?;

    String weightInfo;
    if (currentWeight != null) {
      final lbs = (currentWeight * 2.20462).toStringAsFixed(1);
      final goalLbs = goalWeight != null
          ? ' Goal weight: ${(goalWeight * 2.20462).toStringAsFixed(1)} lbs.'
          : '';
      weightInfo = 'Current weight: $lbs lbs.$goalLbs';
    } else {
      weightInfo = 'No weight logged yet.';
    }

    return """You are Slay, a supportive and motivating AI fitness coach inside the SlayFit app.

User: $name
Today's data:
- Calories: $calories / $calorieGoal kcal
- Protein: ${proteinG}g | Carbs: ${carbsG}g | Fat: ${fatG}g
- Water: ${waterMl}ml
- Current streak: $streak days
- $weightInfo

Be concise (2-3 sentences max unless asked for more). Be warm, direct, and science-backed.
Use the user's actual data to give personalized advice. Never make up data you don't have.""";
  }

  static Future<String> sendMessage({
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> context,
  }) async {
    // Build Gemini-format contents (role: "user" | "model")
    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      contents.add({
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_kModel:generateContent?key=$_kGeminiApiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [{'text': _buildSystemPrompt(context)}],
        },
        'contents': contents,
        'generationConfig': {'maxOutputTokens': 512},
      }),
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw Exception('api_error_${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
