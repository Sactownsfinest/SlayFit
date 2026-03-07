import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../main.dart';
import '../providers/food_provider.dart';
import '../providers/water_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/user_provider.dart';
import '../services/claude_service.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final SpeechToText _speech = SpeechToText();
  bool _loading = false;
  bool _tipRequested = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (!_tipRequested) {
      _tipRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestDailyTip());
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device.')),
      );
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _inputCtrl.text = result.recognizedWords;
          _inputCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputCtrl.text.length),
          );
        });
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Map<String, dynamic> _buildContext() {
    final food = ref.read(foodLogProvider);
    final water = ref.read(waterProvider);
    final streak = ref.read(streakProvider);
    final weight = ref.read(weightProvider);
    final profile = ref.read(userProfileProvider);

    return {
      'name': profile.name,
      'calories': food.totalCalories.round(),
      'calorieGoal': profile.dailyCalorieGoal,
      'proteinG': food.totalProtein.round(),
      'carbsG': food.totalCarbs.round(),
      'fatG': food.totalFat.round(),
      'waterMl': water.todayTotalMl,
      'streak': streak.currentStreak,
      'currentWeight': weight.entries.isNotEmpty ? weight.entries.last.weightKg : null,
      'goalWeight': weight.goalWeightKg,
    };
  }

  Future<void> _requestDailyTip() async {
    await _sendToApi(
      'Give me a short personalized tip for today based on my current stats.',
      isAutoTip: true,
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();
    await _sendToApi(text);
  }

  Future<void> _sendMealPlan() async {
    if (_loading) return;
    final ctx = _buildContext();
    final cal = ctx['calorieGoal'] ?? 2000;
    final p = ctx['proteinG'] ?? 150;
    final c = ctx['carbsG'] ?? 200;
    final f = ctx['fatG'] ?? 65;
    await _sendToApi(
      'Generate a 7-day meal plan for me. My daily calorie goal is ${cal}kcal, '
      'macros: ${p}g protein, ${c}g carbs, ${f}g fat. '
      'Format as Day 1: Breakfast: ..., Lunch: ..., Dinner: ..., Snack: ...',
    );
  }

  Future<void> _sendToApi(String userText, {bool isAutoTip = false}) async {
    if (!isAutoTip) {
      setState(() => _messages.add(_ChatMessage(role: 'user', text: userText)));
    }
    setState(() => _loading = true);
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !m.isAutoTip)
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final reply = await ClaudeService.sendMessage(
        history: history,
        userMessage: userText,
        context: _buildContext(),
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', text: reply, isAutoTip: isAutoTip));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isAutoTip) {
            final raw = e.toString();
            final String msg;
            if (raw.contains('429') || raw.contains('RESOURCE_EXHAUSTED') || raw.contains('quota')) {
              msg = 'AI quota limit reached. Please try again in a few minutes.';
            } else if (raw.contains('timeout') || raw.contains('SocketException')) {
              msg = 'Connection timed out. Check your internet and try again.';
            } else {
              msg = 'Error: ${raw.length > 300 ? raw.substring(0, 300) : raw}';
            }
            _messages.add(_ChatMessage(role: 'assistant', text: msg));
          }
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: kNeonYellow, size: 22),
            SizedBox(width: 8),
            Text('AI Coach'),
          ],
        ),
      ),
      body: _buildChat(),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator(color: kNeonYellow))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return _buildTypingIndicator();
                    return _buildBubble(_messages[i]);
                  },
                ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: kNeonYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? kNeonYellow.withValues(alpha: 0.15) : kCardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? Border.all(color: kNeonYellow.withValues(alpha: 0.3), width: 1)
                    : null,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? kNeonYellow : kTextPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: kNeonYellow, shape: BoxShape.circle),
            child: const Icon(Icons.psychology, color: Colors.black, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: _TypingDots(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
      decoration: const BoxDecoration(
        color: kSurfaceDark,
        border: Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('7-Day Meal Plan'),
                  avatar: const Icon(Icons.restaurant_menu,
                      size: 16, color: Colors.black),
                  backgroundColor: kNeonYellow,
                  labelStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  onPressed: _sendMealPlan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
          // Mic button
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening ? kNeonYellow : kCardDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isListening ? kNeonYellow : const Color(0xFF2A3550),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.black : kTextSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Ask your coach...',
                hintStyle: TextStyle(
                  color: _isListening ? kNeonYellow : kTextSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2A3550)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _isListening ? kNeonYellow : const Color(0xFF2A3550),
                    width: _isListening ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: kNeonYellow, width: 1.5),
                ),
                filled: true,
                fillColor: kCardDark,
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: kNeonYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final bool isAutoTip;
  const _ChatMessage({required this.role, required this.text, this.isAutoTip = false});
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(radius: 4, backgroundColor: kTextSecondary),
              ),
            );
          }),
        );
      },
    );
  }
}
