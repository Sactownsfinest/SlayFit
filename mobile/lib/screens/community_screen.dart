import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../main.dart';
import '../providers/activity_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/food_provider.dart';
import '../providers/challenges_provider.dart';
import '../providers/health_provider.dart';
import '../providers/water_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';
import '../data/challenge_definitions.dart';
import '../services/firebase_service.dart';

// ── Root Screen ───────────────────────────────────────────────────────────────

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  bool _initialized = false;
  bool _initializing = false;
  String _displayName = '';
  String _initError = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() => setState(() {}));
    _init();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (_initializing) return;
    _initializing = true;
    try {
      await FirebaseService.ensureSignedIn();
      _displayName = await FirebaseService.getDisplayName();
      FirebaseService.registerUser(_displayName); // register for in-app search
      if (mounted) setState(() { _initialized = true; _initError = ''; });
    } catch (e) {
      if (mounted) setState(() { _initialized = false; _initError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people, color: kNeonYellow, size: 20),
            SizedBox(width: 8),
            Text('Community'),
          ],
        ),
        actions: [
          if (_initialized)
            IconButton(
              icon: const Icon(Icons.person_outline, color: kTextSecondary),
              onPressed: () => _showNameDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kNeonYellow,
          labelColor: kNeonYellow,
          unselectedLabelColor: kTextSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'Challenges'),
            const Tab(text: 'My Progress'),
            const Tab(text: 'Leaderboard'),
            const Tab(text: 'Chat'),
            Tab(
              child: StreamBuilder<List<AppNotification>>(
                stream: FirebaseService.myNotificationsStream(),
                builder: (_, snap) {
                  final unread = (snap.data ?? []).where((n) => !n.read).length;
                  return Stack(clipBehavior: Clip.none, children: [
                    const Text('Alerts'),
                    if (unread > 0)
                      Positioned(
                        right: -10,
                        top: -4,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                        ),
                      ),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
      body: !_initialized
          ? _buildInitFailed()
          : TabBarView(
              controller: _tab,
              children: [
                _AllChallengesTab(),
                _MyProgressTab(),
                _LeaderboardTab(),
                _ChatTab(displayName: _displayName),
                _NotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildInitFailed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: kTextSecondary, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to connect to Firebase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary)),
          if (_initError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_initError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initialized = false;
                _initializing = false;
              });
              _init();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow, foregroundColor: Colors.black),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showNameDialog() {
    final ctrl = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Your Display Name',
            style: TextStyle(color: kTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: kTextSecondary),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              await FirebaseService.setDisplayName(name);
              if (mounted) setState(() => _displayName = name);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Challenge catalog helpers ─────────────────────────────────────────────────

Color _catColor(ChallengeCategory c) {
  switch (c) {
    case ChallengeCategory.daily:     return kNeonYellow;
    case ChallengeCategory.weekly:    return const Color(0xFFFF9500);
    case ChallengeCategory.thirtyDay: return const Color(0xFFFF3B30);
    case ChallengeCategory.lifestyle: return const Color(0xFF34C759);
    case ChallengeCategory.social:    return const Color(0xFF007AFF);
    case ChallengeCategory.signature: return const Color(0xFFBF5AF2);
  }
}

// ── All Challenges Tab (catalog browser) ─────────────────────────────────────

class _AllChallengesTab extends ConsumerWidget {
  const _AllChallengesTab();

  static const _order = [
    ChallengeCategory.signature,
    ChallengeCategory.daily,
    ChallengeCategory.weekly,
    ChallengeCategory.social,
    ChallengeCategory.thirtyDay,
    ChallengeCategory.lifestyle,
  ];

  static const _headers = {
    ChallengeCategory.signature: '⚡ Signature Slayfit',
    ChallengeCategory.daily:     '🔆 Daily Slay',
    ChallengeCategory.weekly:    '📆 Weekly Consistency',
    ChallengeCategory.social:    '👥 Community',
    ChallengeCategory.thirtyDay: '🔥 30-Day Transformations',
    ChallengeCategory.lifestyle: '🌿 Lifestyle',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        for (final cat in _order) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_headers[cat]!, style: TextStyle(color: _catColor(cat), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ...kAllChallenges.where((c) => c.category == cat).map((def) {
            final isJoined = state.isJoined(def.id);
            final isDone = state.isCompleted(def.id);
            final color = _catColor(def.category);
            return GestureDetector(
              onTap: () => _showChallengeDetail(context, ref, def),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isJoined ? color.withValues(alpha: 0.5) : const Color(0xFF2A3550),
                    width: isJoined ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Center(child: Text(def.badgeEmoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
                                child: Text(def.durationLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Text(def.tagline, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDone)
                        Icon(Icons.check_circle, color: color, size: 22)
                      else if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: Text('Active', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            ref.read(challengesProvider.notifier).joinChallenge(def.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Challenge accepted: ${def.name}'),
                              backgroundColor: color,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                            child: const Text('Join', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ── My Progress Tab (active + completed challenges) ───────────────────────────

class _MyProgressTab extends ConsumerWidget {
  const _MyProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengesProvider);
    final active = state.active;
    final completedIds = state.completedIds;

    if (active.isEmpty && completedIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No challenges yet', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Go to Challenges tab and join your first one.', style: TextStyle(color: kTextSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (active.isNotEmpty) ...[
          const Text('Active', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...active.map((uc) => _ActiveChallengeCard(uc: uc)),
          const SizedBox(height: 20),
        ],
        if (completedIds.isNotEmpty) ...[
          const Text('Completed Badges', style: TextStyle(color: kNeonYellow, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: completedIds.map((id) {
              try {
                final def = kAllChallenges.firstWhere((c) => c.id == id);
                final color = _catColor(def.category);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(def.badgeEmoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(def.badgeName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ── Requirement result model ──────────────────────────────────────────────────

class _ReqResult {
  final double current;
  final double target;
  final String valueLabel; // e.g. "4,200 / 8,000 steps"
  final bool met;

  const _ReqResult({
    required this.current,
    required this.target,
    required this.valueLabel,
    required this.met,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : (met ? 1.0 : 0.0);
}

// ── Active Challenge Card (live metric progress) ───────────────────────────────

class _ActiveChallengeCard extends ConsumerWidget {
  final UserChallenge uc;
  const _ActiveChallengeCard({required this.uc});

  List<_ReqResult> _computeReqs(WidgetRef ref) {
    final def = uc.definition;
    final health = ref.watch(healthProvider);
    final water = ref.watch(waterProvider);
    final food = ref.watch(foodLogProvider);
    final activity = ref.watch(activityProvider);
    final user = ref.watch(userProfileProvider);
    final isMultiDay = def.durationDays > 1;

    return def.requirements.map((req) {
      switch (req.metric) {
        case MetricType.steps:
          final steps = (health.todaySteps ?? 0).toDouble();
          // For multi-day step challenges, show daily quota (total / days)
          final target = isMultiDay
              ? (req.targetValue / def.durationDays).roundToDouble()
              : req.targetValue;
          return _ReqResult(
            current: steps,
            target: target,
            valueLabel: '${_fmtNum(steps)} / ${_fmtNum(target)} steps',
            met: steps >= target,
          );

        case MetricType.water:
          final ml = water.todayTotalMl.toDouble();
          final target = isMultiDay
              ? (req.targetValue / def.durationDays).roundToDouble()
              : req.targetValue;
          return _ReqResult(
            current: ml,
            target: target,
            valueLabel: '${ml.toInt()} / ${target.toInt()} ml',
            met: ml >= target,
          );

        case MetricType.calories:
          final cals = food.totalCalories;
          final goal = food.dailyCalorieGoal;
          if (req.targetValue == -1) {
            // Hit calorie target (within ±10%)
            final hit = cals > 0 && cals >= goal * 0.90 && cals <= goal * 1.10;
            return _ReqResult(
              current: cals,
              target: goal,
              valueLabel: '${cals.toInt()} / ${goal.toInt()} kcal',
              met: hit,
            );
          }
          return _ReqResult(
            current: cals,
            target: req.targetValue,
            valueLabel: '${cals.toInt()} / ${req.targetValue.toInt()} kcal',
            met: cals >= req.targetValue,
          );

        case MetricType.protein:
          final protein = food.totalProtein;
          final goal = req.targetValue == -1
              ? user.proteinGoalG.toDouble()
              : req.targetValue;
          return _ReqResult(
            current: protein,
            target: goal,
            valueLabel: '${protein.toInt()} / ${goal.toInt()} g protein',
            met: protein >= goal,
          );

        case MetricType.workouts:
          final count = activity.todayEntries.length.toDouble();
          // For multi-day: just need 1 workout today to count the day
          final target = isMultiDay ? 1.0 : req.targetValue;
          return _ReqResult(
            current: count,
            target: target,
            valueLabel: count == 0
                ? 'No workout logged yet'
                : '${count.toInt()} workout${count > 1 ? 's' : ''} logged',
            met: count >= target,
          );

        case MetricType.foodLogs:
          final count = food.entries.length.toDouble();
          final target = isMultiDay ? 1.0 : req.targetValue;
          return _ReqResult(
            current: count,
            target: target,
            valueLabel: '${count.toInt()} / ${target.toInt()} meals logged',
            met: count >= target,
          );

        case MetricType.manual:
          final done = uc.checkedInToday;
          return _ReqResult(
            current: done ? 1.0 : 0.0,
            target: 1.0,
            valueLabel: done ? 'Done ✓' : 'Tap below to check in',
            met: done,
          );
      }
    }).toList();
  }

  static String _fmtNum(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    }
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = uc.definition;
    final color = _catColor(def.category);
    final reqs = _computeReqs(ref);
    final allMet = reqs.every((r) => r.met);
    final isManual = def.requirements.any((r) => r.metric == MetricType.manual);
    final checkedIn = uc.checkedInToday;

    // Auto check-in when all metric-based requirements are met
    if (allMet && !isManual && !checkedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(challengesProvider.notifier).checkInToday(def.id);
      });
    }

    // Overall progress bar value
    final double overallProgress;
    final String overallLabel;
    if (def.durationDays == 1) {
      overallProgress = reqs.isEmpty
          ? 0.0
          : reqs.map((r) => r.progress).reduce((a, b) => a < b ? a : b);
      overallLabel = allMet ? 'Complete! ✓' : '${(overallProgress * 100).toInt()}% complete';
    } else {
      overallProgress = uc.progress;
      overallLabel = '${uc.completedDates.length} / ${def.durationDays} days completed';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allMet ? color : color.withValues(alpha: 0.35),
          width: allMet ? 2 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(children: [
              Text(def.badgeEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(def.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                  def.durationDays == 1 ? 'Today' : '${uc.daysRemaining}d left',
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // ── Overall progress bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(overallLabel,
                style: TextStyle(
                    color: allMet ? color : kTextSecondary,
                    fontSize: 11,
                    fontWeight:
                        allMet ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(height: 10),

            // ── Per-requirement progress ──
            ...reqs.asMap().entries.map((e) {
              final req = def.requirements[e.key];
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(req.label,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11)),
                      ),
                      Text(r.valueLabel,
                          style: TextStyle(
                              color: r.met ? color : kTextSecondary,
                              fontSize: 11,
                              fontWeight: r.met
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      if (r.met) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, color: color, size: 13),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: r.progress,
                        backgroundColor: color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(r.met
                            ? color
                            : color.withValues(alpha: 0.55)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Multi-day: today's status ──
            if (def.durationDays > 1 && !isManual)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(children: [
                  Icon(Icons.today, size: 12,
                      color: (allMet || checkedIn) ? color : kTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    checkedIn
                        ? "Today's goal done ✓"
                        : allMet
                            ? 'Marking today complete...'
                            : 'Complete all goals to count today',
                    style: TextStyle(
                        color: (allMet || checkedIn) ? color : kTextSecondary,
                        fontSize: 11,
                        fontStyle: allMet && !checkedIn
                            ? FontStyle.italic
                            : FontStyle.normal),
                  ),
                ]),
              ),

            // ── Manual check-in button ──
            if (isManual && !checkedIn)
              GestureDetector(
                onTap: () {
                  ref
                      .read(challengesProvider.notifier)
                      .checkInToday(def.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${def.badgeEmoji} Checked in!'),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text('Check In Today',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showChallengeDetail(BuildContext context, WidgetRef ref, ChallengeDefinition def) {
  final state = ref.read(challengesProvider);
  final isJoined = state.isJoined(def.id);
  final isDone = state.isCompleted(def.id);
  final color = _catColor(def.category);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF3A4560), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Center(child: Text(def.badgeEmoji, style: const TextStyle(fontSize: 28)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 3),
                Text(def.tagline, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)), child: Text(def.durationLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
              ])),
            ]),
            const SizedBox(height: 16),
            Text(def.description, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            ...def.requirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(req.label, style: const TextStyle(color: kTextPrimary, fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 20),
            if (isDone)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: color, size: 20),
                const SizedBox(width: 8),
                Text('Challenge Complete!', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              ])
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isJoined
                      ? () {
                          ref.read(challengesProvider.notifier).leaveChallenge(def.id);
                          Navigator.pop(context);
                        }
                      : () {
                          ref.read(challengesProvider.notifier).joinChallenge(def.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Challenge accepted: ${def.name}'),
                            backgroundColor: color,
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined ? const Color(0xFF2A3550) : color,
                    foregroundColor: isJoined ? kTextSecondary : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isJoined ? 'Leave Challenge' : 'Accept Challenge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  'I\'m doing the "${def.name}" challenge on SlayFit! ${def.badgeEmoji}\n\n'
                  '"${def.tagline}"\n\n'
                  'Join me — download SlayFit: https://appdistribution.firebase.dev/i/b170cd7640debdb1',
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Invite a Friend to This Challenge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  side: const BorderSide(color: Color(0xFF2A3550)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Original Firebase Challenges Tab ─────────────────────────────────────────

class _ChallengesTab extends ConsumerStatefulWidget {
  final String displayName;
  const _ChallengesTab({required this.displayName});

  @override
  ConsumerState<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<_ChallengesTab> {
  bool _autoSynced = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SlayChallenge>>(
      stream: FirebaseService.myChallengesStream(),
      builder: (context, snap) {
        final challenges = snap.data ?? [];
        // Auto-sync all scores once when challenges first load
        if (!_autoSynced && challenges.isNotEmpty) {
          _autoSynced = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final c in challenges) {
              _syncScore(c);
            }
          });
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add,
                    label: 'Create Challenge',
                    onTap: () => _showCreateSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.group_add,
                    label: 'Join with Code',
                    onTap: () => _showJoinDialog(context),
                    secondary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (challenges.isEmpty) ...[
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events_outlined,
                  color: kTextSecondary, size: 48),
              const SizedBox(height: 12),
              const Text('No active challenges',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                  'Create a challenge and share the code\nwith friends to compete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
            ] else ...[
              Text('Your Active Challenges (${challenges.length})',
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              ...challenges.map((c) => _ChallengeCard(
                    challenge: c,
                    ref: ref,
                    onSync: () => _syncScore(c),
                    onInviteUser: () => _showInviteUserDialog(context, c),
                  )),
            ],
          ],
        );
      },
    );
  }

  Future<void> _syncScore(SlayChallenge challenge) async {
    final uid = FirebaseService.uid;
    if (uid == null) return;
    double score = 0;
    switch (challenge.type) {
      case ChallengeType.calories:
        score = ref.read(activityProvider).todayCaloriesBurned *
            challenge.durationDays;
        break;
      case ChallengeType.workouts:
        score = ref.read(activityProvider).todayEntries.length.toDouble();
        break;
      case ChallengeType.streak:
        score = ref.read(streakProvider).currentStreak.toDouble();
        break;
      case ChallengeType.goalHits:
        final food = ref.read(foodLogProvider);
        score = food.totalCalories >= food.dailyCalorieGoal ? 1 : 0;
        break;
    }
    await FirebaseService.updateMyScore(challenge.id, score);
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateChallengeSheet(
          displayName: widget.displayName,
          onCreated: (c) {
            _showShareCode(context, c);
          }),
    );
  }

  void _showShareCode(BuildContext context, SlayChallenge c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Challenge Created! 🎉',
            style: TextStyle(color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with friends:',
                style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: c.joinCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: kNeonYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kNeonYellow.withValues(alpha: 0.5), width: 2),
                ),
                child: Text(
                  c.joinCode,
                  style: const TextStyle(
                      color: kNeonYellow,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to copy',
                style: TextStyle(color: kTextSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                'Join my SlayFit challenge! 💪\n\n'
                'Use code: ${c.joinCode}\n\n'
                'Download SlayFit: https://appdistribution.firebase.dev/i/b170cd7640debdb1',
              );
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showInviteUserDialog(BuildContext context, SlayChallenge challenge) {
    final ctrl = TextEditingController();
    List<Map<String, String>> results = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: kCardDark,
          title: const Text('Invite a SlayFit User', style: TextStyle(color: kTextPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invite someone to "${challenge.title}"', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by display name',
                    hintStyle: const TextStyle(color: kTextSecondary),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    suffixIcon: searching
                        ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: kNeonYellow)))
                        : const Icon(Icons.search, color: kTextSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kNeonYellow, width: 1.5)),
                  ),
                  onChanged: (v) async {
                    if (v.trim().length < 2) { setSt(() => results = []); return; }
                    setSt(() => searching = true);
                    final found = await FirebaseService.searchUsers(v.trim());
                    setSt(() { results = found; searching = false; });
                  },
                ),
                if (results.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final user = results[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, color: kTextSecondary, size: 20),
                          title: Text(user['displayName'] ?? '', style: const TextStyle(color: kTextPrimary, fontSize: 13)),
                          trailing: TextButton(
                            onPressed: () async {
                              await FirebaseService.sendChallengeInviteToUser(
                                toUid: user['uid']!,
                                challengeName: challenge.title,
                                joinCode: challenge.joinCode,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Invite sent to ${user['displayName']}!'),
                                  backgroundColor: kNeonYellow,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            },
                            child: const Text('Invite', style: TextStyle(color: kNeonYellow, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Join Challenge',
            style: TextStyle(color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-letter code from your friend:',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                  color: kNeonYellow,
                  fontSize: 20,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: kNeonYellow, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.length != 6) return;
              Navigator.pop(context);
              final challenge =
                  await FirebaseService.joinChallenge(code);
              if (!mounted) return;
              if (challenge == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Code not found. Check with your friend.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Joined "${challenge.title}"! Good luck! 🏆')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

// ── Challenge Card ────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final SlayChallenge challenge;
  final WidgetRef ref;
  final VoidCallback onSync;
  final VoidCallback onInviteUser;

  const _ChallengeCard({
    required this.challenge,
    required this.ref,
    required this.onSync,
    required this.onInviteUser,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.uid ?? '';
    final rank = challenge.myRank(uid);
    final score = challenge.myScore(uid);
    final color = _rankColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.type.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(
                        '${challenge.type.label} · ${challenge.daysLeft} days left',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  rank == 0 ? '–' : '#$rank',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)} ${challenge.type.unit}',
                    style: const TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const Text('Your score',
                      style: TextStyle(
                          color: kTextSecondary, fontSize: 11)),
                ],
              ),
              const Spacer(),
              Text(
                '${challenge.participants.length} participant${challenge.participants.length == 1 ? '' : 's'}',
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Share.share(
                  'Join my "${challenge.title}" challenge on SlayFit! 💪\n\n'
                  'Use code: ${challenge.joinCode}\n\n'
                  'Download SlayFit: https://appdistribution.firebase.dev/i/b170cd7640debdb1',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        challenge.joinCode,
                        style: const TextStyle(
                            color: kNeonYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.share, color: kNeonYellow, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSync,
                  icon: const Icon(Icons.sync, size: 14),
                  label: const Text('Sync Score'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kNeonYellow,
                    side: BorderSide(color: kNeonYellow.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInviteUser,
                  icon: const Icon(Icons.person_add_outlined, size: 14),
                  label: const Text('Invite User'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF), width: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return kTextSecondary;
  }
}

// ── Create Challenge Sheet ────────────────────────────────────────────────────

class _CreateChallengeSheet extends ConsumerStatefulWidget {
  final String displayName;
  final void Function(SlayChallenge) onCreated;

  const _CreateChallengeSheet(
      {required this.displayName, required this.onCreated});

  @override
  ConsumerState<_CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState
    extends ConsumerState<_CreateChallengeSheet> {
  final _titleCtrl = TextEditingController();
  ChallengeType _type = ChallengeType.workouts;
  int _duration = 7;
  bool _creating = false;

  static const _durations = [3, 7, 14, 30];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('New Challenge',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    color: kTextSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Challenge name (e.g. Weekend Warriors)',
              hintStyle:
                  const TextStyle(color: kTextSecondary, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: kNeonYellow, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Challenge Type',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChallengeType.values.map((t) {
              final selected = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? kNeonYellow.withValues(alpha: 0.15)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? kNeonYellow
                          : const Color(0xFF2A3550),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${t.emoji} ${t.label}',
                    style: TextStyle(
                        color:
                            selected ? kNeonYellow : kTextSecondary,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Duration',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: _durations.map((d) {
              final selected = _duration == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _duration = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? kNeonYellow.withValues(alpha: 0.15)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? kNeonYellow
                              : const Color(0xFF2A3550),
                          width: selected ? 1.5 : 1),
                    ),
                    child: Text('$d days',
                        style: TextStyle(
                            color: selected
                                ? kNeonYellow
                                : kTextSecondary,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Text('Create & Get Code',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a challenge name')));
      return;
    }
    setState(() => _creating = true);
    try {
      final challenge = await FirebaseService.createChallenge(
          title: title, type: _type, durationDays: _duration);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(challenge);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create. Try again.')));
      }
    }
  }
}

// ── Leaderboard Tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  SlayChallenge? _selected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SlayChallenge>>(
      stream: FirebaseService.myChallengesStream(),
      builder: (context, snap) {
        final challenges = snap.data ?? [];
        if (challenges.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard_outlined,
                    color: kTextSecondary, size: 48),
                SizedBox(height: 12),
                Text('Join a challenge to\nsee leaderboards!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        _selected ??= challenges.first;
        // Find the current version of _selected in the stream
        final current = challenges.firstWhere((c) => c.id == _selected!.id,
            orElse: () => challenges.first);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Challenge selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: challenges.map((c) {
                  final sel = c.id == current.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? kNeonYellow.withValues(alpha: 0.15)
                            : kCardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? kNeonYellow
                              : const Color(0xFF2A3550),
                        ),
                      ),
                      child: Text(
                        '${c.type.emoji} ${c.title}',
                        style: TextStyle(
                            color:
                                sel ? kNeonYellow : kTextSecondary,
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(current.type.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.title,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontWeight: FontWeight.bold)),
                        Text(
                            '${current.type.label} · ${current.daysLeft} days left',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._buildLeaderboard(current),
          ],
        );
      },
    );
  }

  List<Widget> _buildLeaderboard(SlayChallenge c) {
    final sorted = [...c.participants]
      ..sort((a, b) => b.score.compareTo(a.score));
    final uid = FirebaseService.uid ?? '';

    return sorted.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final p = entry.value;
      final isMe = p.userId == uid;

      final rankColor = rank == 1
          ? const Color(0xFFFFD700)
          : rank == 2
              ? const Color(0xFFC0C0C0)
              : rank == 3
                  ? const Color(0xFFCD7F32)
                  : kTextSecondary;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? kNeonYellow.withValues(alpha: 0.07)
              : kCardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? kNeonYellow.withValues(alpha: 0.4)
                : const Color(0xFF2A3550),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
                style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: rank <= 3 ? 20 : 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${p.displayName}${isMe ? ' (You)' : ''}',
                style: TextStyle(
                  color: isMe ? kNeonYellow : kTextPrimary,
                  fontWeight:
                      isMe ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${p.score.toStringAsFixed(0)} ${c.type.unit}',
              style: TextStyle(
                  color: isMe ? kNeonYellow : kTextSecondary,
                  fontWeight:
                      isMe ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ── Chat Tab ──────────────────────────────────────────────────────────────────

class _ChatTab extends ConsumerStatefulWidget {
  final String displayName;
  const _ChatTab({required this.displayName});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final SpeechToText _speech = SpeechToText();
  bool _sending = false;
  bool _speechAvailable = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize();
    if (mounted) setState(() => _speechAvailable = ok);
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      if (_inputCtrl.text.trim().isNotEmpty) _send();
      return;
    }
    setState(() {
      _listening = true;
      _inputCtrl.clear();
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _inputCtrl.text = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() => _listening = false);
          _send();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    try {
      await FirebaseService.sendChatMessage(text);
      _scrollToBottom();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMsg>>(
            stream: FirebaseService.chatStream(),
            builder: (context, snap) {
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return const Center(
                  child: Text('No messages yet.\nBe the first to say hi! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextSecondary)),
                );
              }
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: msgs.length,
                itemBuilder: (_, i) => _ChatBubble(
                  msg: msgs[i],
                  isMe: msgs[i].userId == FirebaseService.uid,
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 12),
          decoration: const BoxDecoration(
            color: kSurfaceDark,
            border:
                Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
          ),
          child: Row(
            children: [
              if (_speechAvailable) ...[
                GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _listening ? kNeonYellow : kCardDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _listening ? kNeonYellow : const Color(0xFF2A3550),
                      ),
                    ),
                    child: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? Colors.black : kTextSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _listening ? 'Listening...' : 'Say something...',
                    hintStyle: TextStyle(
                      color: _listening ? kNeonYellow : kTextSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: kCardDark,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFF2A3550))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFF2A3550))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: kNeonYellow, width: 1.5)),
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: kNeonYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.send,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final bool isMe;

  const _ChatBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(msg.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(msg.displayName,
                  style: const TextStyle(
                      color: kNeonYellow,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe
                        ? kNeonYellow.withValues(alpha: 0.15)
                        : kCardDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 3),
                      bottomRight: Radius.circular(isMe ? 3 : 14),
                    ),
                    border: isMe
                        ? Border.all(
                            color: kNeonYellow.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(msg.text,
                      style: TextStyle(
                          color: isMe ? kNeonYellow : kTextPrimary,
                          fontSize: 14,
                          height: 1.4)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(time,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: secondary ? kCardDark : kNeonYellow,
          borderRadius: BorderRadius.circular(12),
          border: secondary
              ? Border.all(color: kNeonYellow.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: secondary ? kNeonYellow : Colors.black, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: secondary ? kNeonYellow : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications Tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: FirebaseService.myNotificationsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonYellow));
        }
        final notifs = snap.data ?? [];
        if (notifs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, color: kTextSecondary, size: 48),
                SizedBox(height: 16),
                Text('No notifications yet', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Challenge invites and acceptances\nwill appear here.', textAlign: TextAlign.center, style: TextStyle(color: kTextSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: notifs.length,
          itemBuilder: (_, i) => _NotifCard(notif: notifs[i]),
        );
      },
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isInvite = notif.type == 'challenge_invite';
    final color = isInvite ? const Color(0xFF007AFF) : const Color(0xFF34C759);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notif.read ? kCardDark : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notif.read ? const Color(0xFF2A3550) : color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isInvite ? Icons.emoji_events_outlined : Icons.check_circle_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInvite
                        ? '${notif.fromName} invited you to a challenge'
                        : '${notif.fromName} accepted your challenge invite',
                    style: TextStyle(color: kTextPrimary, fontWeight: notif.read ? FontWeight.normal : FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (!notif.read)
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ],
            ),
            if (notif.challengeName != null) ...[
              const SizedBox(height: 4),
              Text('"${notif.challengeName}"', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 10),
            if (isInvite)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseService.acceptChallengeInvite(notif);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Joined "${notif.challengeName}"! 🏆'),
                            backgroundColor: kNeonYellow,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => FirebaseService.deleteNotification(notif.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextSecondary,
                        side: const BorderSide(color: Color(0xFF2A3550)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => FirebaseService.markNotificationRead(notif.id),
                  child: const Text('Dismiss', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
