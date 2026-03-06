import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClaudeService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('claude_api_key') ?? '';
    return key.isEmpty ? null : key;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('claude_api_key', key.trim());
  }

  /// Send a chat message with user fitness context injected into the system prompt.
  /// [history] is a list of prior messages: [{'role': 'user'|'assistant', 'content': '...'}]
  /// [userMessage] is the new message from the user.
  /// [context] contains live fitness data to inject.
  /// Returns the assistant reply text, or throws on error.
  static Future<String> sendMessage({
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> context,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) throw Exception('no_api_key');

    final systemPrompt = _buildSystemPrompt(context);

    final messages = [
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 512,
        'system': systemPrompt,
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) throw Exception('invalid_api_key');
    if (response.statusCode != 200) {
      throw Exception('api_error_${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return (content.first as Map<String, dynamic>)['text'] as String;
  }

  static String _buildSystemPrompt(Map<String, dynamic> ctx) {
    final calories = ctx['calories'] ?? 0;
    final calorieGoal = ctx['calorieGoal'] ?? 2000;
    final proteinG = ctx['proteinG'] ?? 0;
    final carbsG = ctx['carbsG'] ?? 0;
    final fatG = ctx['fatG'] ?? 0;
    final waterMl = ctx['waterMl'] ?? 0;
    final streak = ctx['streak'] ?? 0;
    final currentWeight = ctx['currentWeight'];
    final goalWeight = ctx['goalWeight'];
    final name = ctx['name'] ?? 'User';

    final weightInfo = currentWeight != null
        ? 'Current weight: ${currentWeight.toStringAsFixed(1)} kg. Goal weight: ${goalWeight?.toStringAsFixed(1) ?? '?'} kg.'
        : 'No weight logged yet.';

    return '''You are Slay, a supportive and motivating AI fitness coach inside the SlayFit app.

User: $name
Today's data:
- Calories: $calories / $calorieGoal kcal
- Protein: ${proteinG}g | Carbs: ${carbsG}g | Fat: ${fatG}g
- Water: ${waterMl}ml
- Current streak: $streak days
- $weightInfo

Be concise (2-3 sentences max unless asked for more). Be warm, direct, and science-backed.
Use the user's actual data to give personalized advice. Never make up data you don't have.''';
  }
}
