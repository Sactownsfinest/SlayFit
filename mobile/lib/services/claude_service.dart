import 'dart:convert';
import 'package:http/http.dart' as http;

const _kGroqApiKey = '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';
const _kModel = 'llama-3.3-70b-versatile';

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

    return """You are Slay, a warm and motivating AI personal fitness coach in the SlayFit app. You speak conversationally — your responses are read aloud to the user, so keep them natural, concise, and friendly. Avoid bullet points and markdown; use plain sentences instead.

User: $name
Today's data:
- Calories: $calories / $calorieGoal kcal
- Protein: ${proteinG}g | Carbs: ${carbsG}g | Fat: ${fatG}g
- Water: ${waterMl}ml
- Current streak: $streak days
- $weightInfo

Response style:
- Keep answers to 1-3 short sentences for simple questions. Only give longer answers when the user explicitly asks for a plan or detailed advice.
- Be warm, direct, and science-backed. Use the user's actual data to personalize every response.
- Never make up data you don't have.
- Do NOT use asterisks, bullet points, pound signs, or markdown formatting.

FOOD LOGGING: ONLY include the food log marker when the user explicitly asks to log or track something they ate right now — phrases like "log this", "add this to my log", "I just ate X", "track X for me", "I had X for breakfast". Do NOT log food when the user is asking for advice, discussing nutrition, asking about foods, or talking about meal plans. When in doubt, do NOT log. When logging, include the marker at the very end of your response on its own line (valid JSON, no extra spaces):
__FOOD_LOG__{"name":"Food Name","calories":300,"protein":25,"carbs":20,"fat":10,"servingSize":1,"servingUnit":"serving","meal":"snack"}__FOOD_LOG__
The meal field must be one of: breakfast, lunch, dinner, snack. Use best nutritional estimate.

WATER LOGGING: When the user says they drank water or asks to log water, include a water log marker at the very end of your response, formatted EXACTLY like this:
__WATER_LOG__{"ml":250}__WATER_LOG__
Convert cups/glasses/bottles to ml (1 cup=240ml, 1 glass=250ml, 1 bottle=500ml). Only include when logging water.""";
  }

  static Future<Map<String, dynamic>> generateGroceryList({
    required int calorieGoal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required String name,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kGroqApiKey',
      },
      body: jsonEncode({
        'model': _kModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition expert. Respond ONLY with valid JSON — no markdown, no explanation, no extra text.',
          },
          {
            'role': 'user',
            'content':
                'Create a 7-day meal plan for $name with a daily goal of ${calorieGoal}kcal, ${proteinG}g protein, ${carbsG}g carbs, ${fatG}g fat. '
                'Then list every unique grocery ingredient needed for the full week. '
                'Return exactly this JSON structure (no other text): '
                '{"mealPlan":"Day 1\\nBreakfast: ...\\nLunch: ...\\nDinner: ...\\nSnack: ...\\n\\nDay 2\\n...", '
                '"groceries":[{"item":"chicken breast","qty":"2 lbs","category":"Protein"}]} '
                'Category must be one of: Produce, Protein, Dairy, Grains, Pantry, Other.',
          },
        ],
        'max_tokens': 2000,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('api_error_${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    // Strip any accidental markdown fences the model adds
    final clean = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    return jsonDecode(clean) as Map<String, dynamic>;
  }

  static Future<String> sendMessage({
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> context,
  }) async {
    // Build messages array (OpenAI-compatible format)
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _buildSystemPrompt(context)},
    ];
    for (final m in history) {
      messages.add({'role': m['role']!, 'content': m['content']!});
    }
    messages.add({'role': 'user', 'content': userMessage});

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kGroqApiKey',
      },
      body: jsonEncode({
        'model': _kModel,
        'messages': messages,
        'max_tokens': 512,
      }),
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw Exception('api_error_${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }
}
