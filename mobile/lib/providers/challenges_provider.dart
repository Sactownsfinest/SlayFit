import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/challenge_definitions.dart';
import '../services/cloud_sync_service.dart';

// ── Model ───────────────────────────────────────────────────────────────────

class UserChallenge {
  final String definitionId;
  final DateTime startDate;
  final List<String> completedDates; // YYYY-MM-DD

  const UserChallenge({
    required this.definitionId,
    required this.startDate,
    required this.completedDates,
  });

  ChallengeDefinition get definition =>
      kAllChallenges.firstWhere((c) => c.id == definitionId);

  bool get checkedInToday => completedDates.contains(_todayStr());

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  double get progress {
    final def = definition;
    final needed = def.durationDays;
    if (needed == 1) return checkedInToday ? 1.0 : 0.0;
    return (completedDates.length / needed).clamp(0.0, 1.0);
  }

  bool get isCompleted {
    final def = definition;
    if (def.durationDays == 1) return checkedInToday;
    return completedDates.length >= def.durationDays;
  }

  bool get isFailed {
    final def = definition;
    if (def.durationDays <= 1) return false;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return elapsed >= def.durationDays && !isCompleted;
  }

  int get daysRemaining {
    final endDate = startDate.add(Duration(days: definition.durationDays));
    return endDate.difference(DateTime.now()).inDays.clamp(0, definition.durationDays);
  }

  UserChallenge copyWith({List<String>? completedDates}) => UserChallenge(
        definitionId: definitionId,
        startDate: startDate,
        completedDates: completedDates ?? this.completedDates,
      );

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'startDate': startDate.toIso8601String(),
        'completedDates': completedDates,
      };

  factory UserChallenge.fromJson(Map<String, dynamic> j) => UserChallenge(
        definitionId: j['definitionId'] as String,
        startDate: DateTime.parse(j['startDate'] as String),
        completedDates: List<String>.from(j['completedDates'] as List),
      );
}

// ── State ───────────────────────────────────────────────────────────────────

class ChallengesState {
  final List<UserChallenge> active;
  final List<String> completedIds;

  const ChallengesState({
    this.active = const [],
    this.completedIds = const [],
  });

  bool isJoined(String id) => active.any((c) => c.definitionId == id);
  bool isCompleted(String id) => completedIds.contains(id);

  UserChallenge? getActive(String id) {
    try {
      return active.firstWhere((c) => c.definitionId == id);
    } catch (_) {
      return null;
    }
  }

  ChallengesState copyWith({
    List<UserChallenge>? active,
    List<String>? completedIds,
  }) =>
      ChallengesState(
        active: active ?? this.active,
        completedIds: completedIds ?? this.completedIds,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ChallengesNotifier extends StateNotifier<ChallengesState> {
  ChallengesNotifier() : super(const ChallengesState()) {
    _load();
  }

  static const _keyActive = 'challenges_active_v2';
  static const _keyCompleted = 'challenges_completed_v2';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final activeJson = prefs.getString(_keyActive);
    final completedJson = prefs.getString(_keyCompleted);

    final active = activeJson != null
        ? (jsonDecode(activeJson) as List)
            .map((e) => UserChallenge.fromJson(e as Map<String, dynamic>))
            .toList()
        : <UserChallenge>[];

    final completed = completedJson != null
        ? List<String>.from(jsonDecode(completedJson) as List)
        : <String>[];

    state = ChallengesState(active: active, completedIds: completed);
    // Note: _processCompletions() is NOT called here — only called after
    // explicit check-in to avoid auto-completing challenges on load.
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final activeStr = jsonEncode(state.active.map((c) => c.toJson()).toList());
    final completedStr = jsonEncode(state.completedIds);
    await prefs.setString(_keyActive, activeStr);
    await prefs.setString(_keyCompleted, completedStr);
    CloudSyncService.upload(_keyActive, activeStr);
    CloudSyncService.upload(_keyCompleted, completedStr);
  }

  Future<void> resetAll() async {
    state = const ChallengesState(active: [], completedIds: []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActive);
    await prefs.remove(_keyCompleted);
    await prefs.remove('challenges_active_v1');
    await prefs.remove('challenges_completed_v1');
  }

  /// Move any completed/failed challenges out of active.
  void _processCompletions() {
    final nowCompleted = state.active.where((c) => c.isCompleted).toList();
    if (nowCompleted.isEmpty) return;
    final newIds = [
      ...state.completedIds,
      ...nowCompleted.map((c) => c.definitionId),
    ];
    final stillActive =
        state.active.where((c) => !c.isCompleted && !c.isFailed).toList();
    state = state.copyWith(active: stillActive, completedIds: newIds);
    _save();
  }

  void joinChallenge(String definitionId) {
    if (state.isJoined(definitionId)) return;
    final challenge = UserChallenge(
      definitionId: definitionId,
      startDate: DateTime.now(),
      completedDates: [],
    );
    state = state.copyWith(active: [...state.active, challenge]);
    _save();
  }

  void leaveChallenge(String definitionId) {
    state = state.copyWith(
      active: state.active.where((c) => c.definitionId != definitionId).toList(),
    );
    _save();
  }

  /// Mark today as completed for a challenge.
  /// Returns true if this finishes the challenge.
  bool checkInToday(String definitionId) {
    final today = UserChallenge._todayStr();
    bool completed = false;
    final updated = state.active.map((c) {
      if (c.definitionId != definitionId) return c;
      if (c.completedDates.contains(today)) return c;
      final next = c.copyWith(completedDates: [...c.completedDates, today]);
      if (next.isCompleted) completed = true;
      return next;
    }).toList();
    state = state.copyWith(active: updated);
    _save();
    if (completed) _processCompletions();
    return completed;
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, ChallengesState>((ref) {
  return ChallengesNotifier();
});
