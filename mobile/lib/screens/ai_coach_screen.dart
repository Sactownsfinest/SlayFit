import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../main.dart';
import '../providers/food_provider.dart';
import '../providers/water_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/user_provider.dart';
import '../services/claude_service.dart';

enum _VoiceState { idle, listening, thinking, speaking }

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen>
    with TickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  _VoiceState _voiceState = _VoiceState.idle;
  bool _speechAvailable = false;
  bool _greeted = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late AnimationController _spinCtrl;

  static const _historyKey = 'ai_chat_history_v1';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTts();
    _initSpeech();
    _loadHistory();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.20).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.80).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.50);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _voiceState = _VoiceState.idle);
        _autoStartListening();
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _voiceState = _VoiceState.idle);
    });
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _voiceState = _VoiceState.idle);
      },
      onStatus: (status) {
        if ((status == SpeechToText.doneStatus ||
                status == SpeechToText.notListeningStatus) &&
            mounted &&
            _voiceState == _VoiceState.listening) {
          final text = _inputCtrl.text.trim();
          if (text.isNotEmpty) {
            _sendMessage();
          } else {
            setState(() => _voiceState = _VoiceState.idle);
          }
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      if (list.isNotEmpty && mounted) {
        setState(() {
          _messages.addAll(list.map((m) => _ChatMessage(
                role: m['role'] as String,
                text: m['text'] as String,
                isAutoTip: m['isAutoTip'] as bool? ?? false,
              )));
        });
        return;
      }
    }
    // No history — greet the user
    if (!_greeted) {
      _greeted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendGreeting());
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = _messages.length > 100
        ? _messages.sublist(_messages.length - 100)
        : _messages;
    await prefs.setString(
      _historyKey,
      jsonEncode(toSave
          .map((m) =>
              {'role': m.role, 'text': m.text, 'isAutoTip': m.isAutoTip})
          .toList()),
    );
  }

  Future<void> _sendGreeting() async {
    final name = ref.read(userProfileProvider).name;
    final firstName = name.split(' ').first.isNotEmpty
        ? name.split(' ').first
        : name;
    final greeting =
        'Hi $firstName! How can I help with your weight loss journey today?';
    if (!mounted) return;
    setState(() {
      _messages.add(
          _ChatMessage(role: 'assistant', text: greeting, isAutoTip: true));
    });
    _saveHistory();
    _scrollToBottom();
    await _speak(greeting);
  }

  // Strip all markers and markdown formatting before speaking
  String _cleanForSpeech(String text) {
    return text
        .replaceAll(
            RegExp(r'__[A-Z_]+__\{[\s\S]*?\}__[A-Z_]+__'), '')
        .replaceAll(RegExp(r'[*_`#>]'), '')
        .replaceAll(RegExp(r'\n{2,}'), '. ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'[✓]'), '')
        .trim();
  }

  Future<void> _speak(String text) async {
    String clean = _cleanForSpeech(text);
    if (clean.isEmpty) return;
    // For very long responses (meal plans etc.) just read an intro
    if (clean.length > 350) {
      final dot = clean.indexOf('.', 200);
      clean = dot != -1
          ? '${clean.substring(0, dot + 1)} I\'ve put the full details in the chat below.'
          : '${clean.substring(0, 280)}. Full details are in the chat.';
    }
    setState(() => _voiceState = _VoiceState.speaking);
    await _tts.speak(clean);
  }

  Future<void> _autoStartListening() async {
    if (!_speechAvailable || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted && _voiceState == _VoiceState.idle) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    await _tts.stop();
    setState(() {
      _voiceState = _VoiceState.listening;
      _inputCtrl.clear();
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _inputCtrl.text = result.recognizedWords;
          _inputCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputCtrl.text.length),
          );
        });
        if (result.finalResult &&
            result.recognizedWords.trim().isNotEmpty) {
          setState(() => _voiceState = _VoiceState.thinking);
          _sendMessage();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _voiceState = _VoiceState.idle);
  }

  // Mic button: tap to start/stop listening; tap when speaking to interrupt
  Future<void> _toggleMic() async {
    if (_voiceState == _VoiceState.speaking) {
      await _tts.stop();
      setState(() => _voiceState = _VoiceState.idle);
      return;
    }
    if (_voiceState == _VoiceState.listening) {
      await _stopListening();
      return;
    }
    if (_voiceState == _VoiceState.thinking) return;
    await _startListening();
  }

  String _processReply(String reply) {
    String processed = reply;

    // Food logging
    final foodPat = RegExp(r'__FOOD_LOG__(\{[\s\S]+?\})__FOOD_LOG__');
    final foodMatch = foodPat.firstMatch(processed);
    if (foodMatch != null) {
      try {
        final json =
            jsonDecode(foodMatch.group(1)!) as Map<String, dynamic>;
        final mealStr = (json['meal'] as String? ?? 'snack').toLowerCase();
        final meal = MealType.values.firstWhere(
          (m) => m.name == mealStr,
          orElse: () => MealType.snack,
        );
        ref.read(foodLogProvider.notifier).addEntry(FoodEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: json['name'] as String,
              calories: (json['calories'] as num).toDouble(),
              protein: (json['protein'] as num).toDouble(),
              carbs: (json['carbs'] as num).toDouble(),
              fat: (json['fat'] as num).toDouble(),
              servingSize: (json['servingSize'] as num? ?? 1).toDouble(),
              servingUnit: json['servingUnit'] as String? ?? 'serving',
              meal: meal,
              loggedAt: DateTime.now(),
            ));
        processed = processed.replaceAll(foodPat, '').trim();
        processed = '$processed\n\nLogged to your food diary.';
      } catch (_) {
        processed = processed.replaceAll(foodPat, '').trim();
      }
    }

    // Water logging
    final waterPat = RegExp(r'__WATER_LOG__(\{[\s\S]+?\})__WATER_LOG__');
    final waterMatch = waterPat.firstMatch(processed);
    if (waterMatch != null) {
      try {
        final json =
            jsonDecode(waterMatch.group(1)!) as Map<String, dynamic>;
        final ml = (json['ml'] as num).toInt();
        ref.read(waterProvider.notifier).addWater(ml);
        processed = processed.replaceAll(waterPat, '').trim();
        processed = '$processed\n\nLogged ${ml}ml of water.';
      } catch (_) {
        processed = processed.replaceAll(waterPat, '').trim();
      }
    }

    return processed;
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
      'currentWeight': weight.entries.isNotEmpty
          ? weight.entries.last.weightKg
          : null,
      'goalWeight': weight.goalWeightKg,
    };
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _voiceState == _VoiceState.thinking) return;
    _inputCtrl.clear();
    await _speech.stop();
    await _sendToApi(text);
  }

  Future<void> _sendMealPlan() async {
    if (_voiceState == _VoiceState.thinking) return;
    final ctx = _buildContext();
    final cal = ctx['calorieGoal'] ?? 2000;
    final p = ctx['proteinG'] ?? 150;
    final c = ctx['carbsG'] ?? 200;
    final f = ctx['fatG'] ?? 65;
    await _sendToApi(
      'Generate a 7-day meal plan for me. My daily calorie goal is ${cal}kcal, '
      'macros: ${p}g protein, ${c}g carbs, ${f}g fat. '
      'Format as Day 1: Breakfast ..., Lunch ..., Dinner ..., Snack ...',
    );
  }

  Future<void> _sendToApi(String userText, {bool isAutoTip = false}) async {
    if (!isAutoTip) {
      setState(() {
        _messages.add(_ChatMessage(role: 'user', text: userText));
        _voiceState = _VoiceState.thinking;
      });
      _saveHistory();
    }
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !m.isAutoTip)
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final raw = await ClaudeService.sendMessage(
        history: history,
        userMessage: userText,
        context: _buildContext(),
      );
      final reply = _processReply(raw);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
              role: 'assistant', text: reply, isAutoTip: isAutoTip));
        });
        _saveHistory();
        _scrollToBottom();
        await _speak(reply);
      }
    } catch (e) {
      if (mounted) {
        const errMsg =
            "Sorry, I couldn't connect right now. Please check your internet and try again.";
        setState(() {
          if (!isAutoTip) {
            _messages.add(
                const _ChatMessage(role: 'assistant', text: errMsg));
          }
          _voiceState = _VoiceState.idle;
        });
        if (!isAutoTip) await _speak(errMsg);
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
    _tts.stop();
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
      body: Column(
        children: [
          _buildVoiceAvatar(),
          const Divider(height: 1, color: Color(0xFF2A3550)),
          Expanded(child: _buildChatList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildVoiceAvatar() {
    final Color ringColor;
    final String stateLabel;
    final bool pulse;
    switch (_voiceState) {
      case _VoiceState.listening:
        ringColor = kNeonYellow;
        stateLabel = 'Listening...';
        pulse = true;
        break;
      case _VoiceState.speaking:
        ringColor = const Color(0xFF60A5FA);
        stateLabel = 'Speaking...';
        pulse = true;
        break;
      case _VoiceState.thinking:
        ringColor = const Color(0xFFA78BFA);
        stateLabel = 'Thinking...';
        pulse = true;
        break;
      case _VoiceState.idle:
        ringColor = const Color(0xFF2A3550);
        stateLabel = 'Tap mic to talk';
        pulse = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      color: kSurfaceDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                if (pulse)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseScale.value,
                      child: Opacity(
                        opacity: _pulseOpacity.value,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: ringColor, width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Spinning arc for thinking state
                if (_voiceState == _VoiceState.thinking)
                  AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _spinCtrl.value * 2 * pi,
                      child: CustomPaint(
                        size: const Size(86, 86),
                        painter: _ArcPainter(color: ringColor),
                      ),
                    ),
                  ),
                // Static ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2),
                    color: ringColor.withValues(alpha: 0.08),
                  ),
                ),
                // Center icon
                Icon(
                  Icons.psychology,
                  color: _voiceState == _VoiceState.idle
                      ? kTextSecondary
                      : ringColor,
                  size: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stateLabel,
            style: TextStyle(
              color: _voiceState == _VoiceState.idle
                  ? kTextSecondary
                  : ringColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final isThinking = _voiceState == _VoiceState.thinking;
    if (_messages.isEmpty && isThinking) {
      return const Center(
          child: CircularProgressIndicator(color: kNeonYellow));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (isThinking ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                  color: kNeonYellow, shape: BoxShape.circle),
              child: const Icon(Icons.psychology,
                  color: Colors.black, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? kNeonYellow.withValues(alpha: 0.15)
                    : kCardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 3),
                  bottomRight: Radius.circular(isUser ? 3 : 14),
                ),
                border: isUser
                    ? Border.all(
                        color: kNeonYellow.withValues(alpha: 0.3),
                        width: 1)
                    : null,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? kNeonYellow : kTextPrimary,
                  fontSize: 13,
                  height: 1.45,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: kNeonYellow, shape: BoxShape.circle),
            child:
                const Icon(Icons.psychology, color: Colors.black, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(14)),
            child: const SizedBox(
                width: 40, height: 14, child: _TypingDots()),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isBusy = _voiceState == _VoiceState.thinking;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
      decoration: const BoxDecoration(
        color: kSurfaceDark,
        border: Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick action chips
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
                      fontSize: 12),
                  onPressed: isBusy ? null : _sendMealPlan,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text("Today's Summary"),
                  avatar: const Icon(Icons.bar_chart, size: 16),
                  onPressed: isBusy
                      ? null
                      : () => _sendToApi(
                          "Give me a quick summary of how I'm doing today."),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Motivate Me'),
                  avatar: const Icon(Icons.bolt, size: 16),
                  onPressed: isBusy
                      ? null
                      : () => _sendToApi(
                          'Give me a short motivational pep talk based on my progress.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Mic / stop button
              GestureDetector(
                onTap: _toggleMic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _voiceState == _VoiceState.listening
                        ? kNeonYellow
                        : _voiceState == _VoiceState.speaking
                            ? const Color(0xFF60A5FA)
                            : kCardDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _voiceState == _VoiceState.listening
                          ? kNeonYellow
                          : _voiceState == _VoiceState.speaking
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2A3550),
                      width: 1.5,
                    ),
                    boxShadow: _voiceState == _VoiceState.listening
                        ? [
                            BoxShadow(
                                color: kNeonYellow.withValues(alpha: 0.4),
                                blurRadius: 14,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: Icon(
                    _voiceState == _VoiceState.listening
                        ? Icons.mic
                        : _voiceState == _VoiceState.speaking
                            ? Icons.stop_rounded
                            : Icons.mic_none,
                    color: (_voiceState == _VoiceState.listening ||
                            _voiceState == _VoiceState.speaking)
                        ? Colors.black
                        : kTextSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _voiceState == _VoiceState.listening
                        ? 'Listening...'
                        : 'Or type here...',
                    hintStyle: TextStyle(
                      color: _voiceState == _VoiceState.listening
                          ? kNeonYellow
                          : kTextSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Color(0xFF2A3550)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: Color(0xFF2A3550), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: kNeonYellow, width: 1.5),
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isBusy ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBusy ? kCardDark : kNeonYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send,
                      color: isBusy ? kTextSecondary : Colors.black,
                      size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data / helpers ────────────────────────────────────────────────────────────

class _ChatMessage {
  final String role;
  final String text;
  final bool isAutoTip;
  const _ChatMessage(
      {required this.role, required this.text, this.isAutoTip = false});
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
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
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final t = (_ctrl.value - delay).clamp(0.0, 1.0);
          final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(
              opacity: opacity,
              child: const CircleAvatar(
                  radius: 4, backgroundColor: kTextSecondary),
            ),
          );
        }),
      ),
    );
  }
}

/// Draws a partial arc for the "thinking" spinner.
class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      pi * 1.25,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
