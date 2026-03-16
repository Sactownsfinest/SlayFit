import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../data/challenge_definitions.dart';
import '../providers/challenges_provider.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/health_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/app_bell_icon.dart';

// ── Category styling ─────────────────────────────────────────────────────────

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

IconData _catIcon(ChallengeCategory c) {
  switch (c) {
    case ChallengeCategory.daily:     return Icons.bolt;
    case ChallengeCategory.weekly:    return Icons.calendar_today;
    case ChallengeCategory.thirtyDay: return Icons.local_fire_department;
    case ChallengeCategory.lifestyle: return Icons.spa_outlined;
    case ChallengeCategory.social:    return Icons.people;
    case ChallengeCategory.signature: return Icons.military_tech;
  }
}

// ── Root Screen ───────────────────────────────────────────────────────────────

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with TickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengesProvider);
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        backgroundColor: kSurfaceDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: kNeonYellow, size: 22),
            SizedBox(width: 8),
            Text('Challenges', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: const [AppBellIcon()],
        bottom: TabBar(
          controller: _tab,
          labelColor: kNeonYellow,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kNeonYellow,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'All'),
            Tab(text: 'Active (${challenges.active.length})'),
            const Tab(text: 'Community'),
            Tab(text: 'Done (${challenges.completedIds.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _AllTab(),
          _ActiveTab(),
          _CommunityTab(),
          _CompletedTab(),
        ],
      ),
    );
  }
}

// ── All Challenges Tab ────────────────────────────────────────────────────────

class _AllTab extends ConsumerWidget {
  const _AllTab();

  static const _order = [
    ChallengeCategory.daily,
    ChallengeCategory.weekly,
    ChallengeCategory.signature,
    ChallengeCategory.thirtyDay,
    ChallengeCategory.lifestyle,
    ChallengeCategory.social,
  ];

  static const _headers = {
    ChallengeCategory.daily: 'Daily Slay Challenges',
    ChallengeCategory.weekly: 'Weekly Consistency',
    ChallengeCategory.signature: 'Signature Slayfit',
    ChallengeCategory.thirtyDay: '30-Day Transformations',
    ChallengeCategory.lifestyle: 'Lifestyle Challenges',
    ChallengeCategory.social: 'Community Challenges',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final cat in _order) ...[
          _CategoryHeader(label: _headers[cat]!, color: _catColor(cat), icon: _catIcon(cat)),
          const SizedBox(height: 10),
          ...kAllChallenges
              .where((c) => c.category == cat)
              .map((def) => _ChallengeCard(def: def)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _CategoryHeader({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final ChallengeDefinition def;
  const _ChallengeCard({required this.def});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengesProvider);
    final isJoined = state.isJoined(def.id);
    final isDone = state.isCompleted(def.id);
    final color = _catColor(def.category);

    return GestureDetector(
      onTap: () => _showDetail(context, ref, def),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(def.badgeEmoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(def.durationLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(def.tagline, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    _JoinButton(def: def, isJoined: isJoined, isDone: isDone, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends ConsumerWidget {
  final ChallengeDefinition def;
  final bool isJoined;
  final bool isDone;
  final Color color;
  const _JoinButton({required this.def, required this.isJoined, required this.isDone, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDone) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 14),
          const SizedBox(width: 4),
          Text('Completed', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );
    }
    if (isJoined) {
      return Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('Active', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(challengesProvider.notifier).leaveChallenge(def.id),
            child: Text('Leave', style: TextStyle(color: kTextSecondary.withValues(alpha: 0.6), fontSize: 11)),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () {
        ref.read(challengesProvider.notifier).joinChallenge(def.id);
        FirebaseService.updateCatalogCheckin(def.id, []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge accepted: ${def.name}'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: const Text('Join', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Active Challenges Tab ─────────────────────────────────────────────────────

class _ActiveTab extends ConsumerStatefulWidget {
  const _ActiveTab();

  @override
  ConsumerState<_ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends ConsumerState<_ActiveTab> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    // Delay 3 s so health/food/water providers have time to load their data
    _syncTimer = Timer(const Duration(seconds: 3), _syncToFirebase);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _syncToFirebase() {
    if (!mounted) return;
    final challenges = ref.read(challengesProvider);
    if (challenges.active.isEmpty) return;
    final health = ref.read(healthProvider);
    final food = ref.read(foodLogProvider);
    final water = ref.read(waterProvider);
    final workout = ref.read(workoutProvider);
    final today = DateTime.now();
    final todayWorkouts = workout.history
        .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day)
        .length;
    for (final uc in challenges.active) {
      FirebaseService.updateCatalogCheckin(
        uc.definitionId,
        uc.completedDates,
        todaySteps: health.todaySteps,
        todayCalories: food.totalCalories.round(),
        todayWaterMl: water.todayTotalMl.toDouble(),
        todayWorkouts: todayWorkouts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengesProvider);
    if (challenges.active.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No active challenges', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Go to "All" and join your first challenge.', style: TextStyle(color: kTextSecondary)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: challenges.active.map((uc) => _ActiveCard(uc: uc)).toList(),
    );
  }
}

class _ActiveCard extends ConsumerWidget {
  final UserChallenge uc;
  const _ActiveCard({required this.uc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = uc.definition;
    final color = _catColor(def.category);
    final progress = uc.progress;
    final daysLeft = uc.daysRemaining;
    final checkedIn = uc.checkedInToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(def.badgeEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(def.tagline, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    def.durationDays == 1 ? 'Today' : '$daysLeft days left',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              def.durationDays == 1
                  ? (checkedIn ? 'Completed today ✓' : 'Not checked in yet')
                  : '${uc.completedDates.length} / ${def.durationDays} days completed',
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _ChallengeAccountabilityRow(challengeId: def.id, def: def),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: checkedIn
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: color, size: 18),
                          const SizedBox(width: 6),
                          Text("Today's check-in complete!", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _showCheckIn(context, ref, uc),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Check In Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Challenge Accountability Row ──────────────────────────────────────────────

class _ChallengeAccountabilityRow extends ConsumerWidget {
  final String challengeId;
  final ChallengeDefinition def;
  const _ChallengeAccountabilityRow({required this.challengeId, required this.def});

  String _metricLabel(Map<String, dynamic> p) {
    // Show the most relevant metric for this challenge type
    final primaryMetric = def.requirements.isNotEmpty ? def.requirements.first.metric : null;
    switch (primaryMetric) {
      case MetricType.steps:
        final steps = p['todaySteps'] as int?;
        return steps != null ? '${steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps' : '— steps';
      case MetricType.calories:
        final cal = p['todayCalories'] as int?;
        return cal != null ? '${cal} kcal' : '— kcal';
      case MetricType.water:
        final ml = p['todayWaterMl'] as double?;
        return ml != null ? '${(ml / 29.5735).round()} oz water' : '— water';
      case MetricType.workouts:
        final w = p['todayWorkouts'] as int?;
        return w != null ? '$w workout${w != 1 ? 's' : ''}' : '— workouts';
      case MetricType.protein:
      case MetricType.foodLogs:
        final cal = p['todayCalories'] as int?;
        return cal != null ? '$cal kcal logged' : '— kcal';
      case MetricType.manual:
      case MetricType.photoChallenge:
      default:
        final dates = (p['completedDates'] as List?)?.length ?? 0;
        return '$dates day${dates != 1 ? 's' : ''} done';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.catalogCheckinStream(challengeId),
      builder: (context, snap) {
        final all = snap.data ?? [];
        for (final p in all) {
          debugPrint('ACCT ROW: uid=${p['uid']} name=${p['displayName']} steps=${p['todaySteps']} myUid=${FirebaseService.uid}');
        }
        if (all.isEmpty) return const SizedBox.shrink();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        // Sort: self first, then by step count descending
        final sorted = [...all]..sort((a, b) {
            final aIsMe = a['uid'] == FirebaseService.uid ? 0 : 1;
            final bIsMe = b['uid'] == FirebaseService.uid ? 0 : 1;
            if (aIsMe != bIsMe) return aIsMe.compareTo(bIsMe);
            // Secondary sort by steps or completion
            final aSteps = a['todaySteps'] as int? ?? (a['completedDates'] as List?)?.length ?? 0;
            final bSteps = b['todaySteps'] as int? ?? (b['completedDates'] as List?)?.length ?? 0;
            return bSteps.compareTo(aSteps);
          });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Color(0xFF2A3550), height: 20),
            const Row(
              children: [
                Icon(Icons.people_outline, color: kTextSecondary, size: 13),
                SizedBox(width: 5),
                Text('Accountability',
                    style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            ...sorted.take(8).map((p) {
              final isMe = p['uid'] == FirebaseService.uid;
              final rawName = p['displayName'] as String? ?? 'Someone';
              final name = isMe ? 'You' : rawName;
              final checkedToday =
                  (p['completedDates'] as List? ?? []).contains(today);
              final avatarColor = isMe ? kNeonYellow : Colors.cyanAccent;
              final metricText = _metricLabel(p);
              final toUid = p['uid'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: avatarColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rawName.isNotEmpty ? rawName[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: avatarColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: isMe ? kNeonYellow : kTextPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          Text(metricText,
                              style: TextStyle(
                                  color: checkedToday
                                      ? Colors.greenAccent
                                      : kTextSecondary,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                    if (checkedToday)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 14),
                      ),
                    // Nudge button (only for other users)
                    if (!isMe && toUid.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          await FirebaseService.sendNudge(
                            toUid: toUid,
                            challengeName: def.name,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nudge sent to $rawName! 👊'),
                                backgroundColor: const Color(0xFFFF9500),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFFF9500).withValues(alpha: 0.4)),
                          ),
                          child: const Text('👊 Nudge',
                              style: TextStyle(
                                  color: Color(0xFFFF9500),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Community Tab ─────────────────────────────────────────────────────────────

class _CommunityTab extends ConsumerWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = kAllChallenges.where((c) => c.category == ChallengeCategory.social).toList();
    final state = ref.watch(challengesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF007AFF).withValues(alpha: 0.2), kCardDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF007AFF), size: 20),
                  SizedBox(width: 8),
                  Text('Community Challenges', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Join a challenge, post your progress in Community chat, and keep each other accountable.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...social.map((def) => _SocialChallengeCard(def: def, state: state)),
      ],
    );
  }
}

class _SocialChallengeCard extends ConsumerWidget {
  final ChallengeDefinition def;
  final ChallengesState state;
  const _SocialChallengeCard({required this.def, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _catColor(def.category);
    final isJoined = state.isJoined(def.id);
    final isDone = state.isCompleted(def.id);
    return GestureDetector(
      onTap: () => _showDetail(context, ref, def),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              Text(def.badgeEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(def.tagline, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _JoinButton(def: def, isJoined: isJoined, isDone: isDone, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Completed Tab ─────────────────────────────────────────────────────────────

class _CompletedTab extends ConsumerWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(challengesProvider).completedIds;
    if (ids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No badges yet', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Complete challenges to earn badges here.', style: TextStyle(color: kTextSecondary)),
          ],
        ),
      );
    }
    final defs = ids
        .map((id) {
          try { return kAllChallenges.firstWhere((c) => c.id == id); }
          catch (_) { return null; }
        })
        .whereType<ChallengeDefinition>()
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: kNeonYellow, size: 18),
              const SizedBox(width: 6),
              Text('${defs.length} Badges Earned', style: const TextStyle(color: kNeonYellow, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: defs.length,
            itemBuilder: (context, i) => _BadgeCard(def: defs[i]),
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final ChallengeDefinition def;
  const _BadgeCard({required this.def});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(def.category);
    return Container(
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), kCardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(def.badgeEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              def.badgeName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(def.categoryLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Challenge Detail Sheet ────────────────────────────────────────────────────

void _showDetail(BuildContext context, WidgetRef ref, ChallengeDefinition def) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DetailSheet(def: def, ref: ref),
  );
}

class _DetailSheet extends ConsumerWidget {
  final ChallengeDefinition def;
  final WidgetRef ref;
  const _DetailSheet({required this.def, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengesProvider);
    final isJoined = state.isJoined(def.id);
    final isDone = state.isCompleted(def.id);
    final color = _catColor(def.category);
    final uc = state.getActive(def.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF3A4560), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Center(child: Text(def.badgeEmoji, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(def.tagline, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(def.categoryLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF2A3550), borderRadius: BorderRadius.circular(6)),
                          child: Text(def.durationLabel, style: const TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Description
            Text(def.description, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            // Requirements
            const Text('Requirements', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...def.requirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(req.label, style: const TextStyle(color: kTextPrimary, fontSize: 13)),
                ],
              ),
            )),
            // Progress if active
            if (uc != null) ...[
              const SizedBox(height: 20),
              const Text('Your Progress', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: uc.progress,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                def.durationDays == 1
                    ? (uc.checkedInToday ? 'Completed today' : 'Not checked in yet')
                    : '${uc.completedDates.length} / ${def.durationDays} days • ${uc.daysRemaining} days remaining',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            // Badge reward
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: kNeonYellow, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reward', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      Text('${def.badgeEmoji} ${def.badgeName} Badge', style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action button
            if (isDone)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text('Challenge Complete!', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              )
            else if (isJoined)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCheckIn(context, ref, uc!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Check In Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      ref.read(challengesProvider.notifier).leaveChallenge(def.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Leave Challenge', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(challengesProvider.notifier).joinChallenge(def.id);
                    FirebaseService.updateCatalogCheckin(def.id, []);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Challenge accepted: ${def.name}'),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Accept Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Check-In Sheet ────────────────────────────────────────────────────────────

void _showCheckIn(BuildContext context, WidgetRef ref, UserChallenge uc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CheckInSheet(uc: uc, ref: ref),
  );
}

class _CheckInSheet extends ConsumerStatefulWidget {
  final UserChallenge uc;
  final WidgetRef ref;
  const _CheckInSheet({required this.uc, required this.ref});

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  bool _manualConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final def = widget.uc.definition;
    final color = _catColor(def.category);

    // Read current metric values
    final food = ref.watch(foodLogProvider);
    final profile = ref.watch(userProfileProvider);
    final water = ref.watch(waterProvider);
    final workout = ref.watch(workoutProvider);
    final health = ref.watch(healthProvider);

    final today = DateTime.now();
    final todayProtein = food.entries
        .where((e) => e.loggedAt.year == today.year && e.loggedAt.month == today.month && e.loggedAt.day == today.day)
        .fold<double>(0, (s, e) => s + e.protein);
    final todayMeals = food.entries
        .where((e) => e.loggedAt.year == today.year && e.loggedAt.month == today.month && e.loggedAt.day == today.day)
        .length;
    final todayWorkouts = workout.history
        .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day)
        .length;

    bool _metricMet(ChallengeRequirement req) {
      switch (req.metric) {
        case MetricType.steps:
          final steps = health.todaySteps ?? 0;
          return steps >= req.targetValue;
        case MetricType.calories:
          if (req.targetValue == -1) {
            final goal = food.dailyCalorieGoal;
            return food.totalCalories >= goal * 0.85 && food.totalCalories <= goal * 1.15;
          }
          return food.totalCalories >= req.targetValue;
        case MetricType.protein:
          if (req.targetValue == -1) return todayProtein >= profile.proteinGoalG;
          return todayProtein >= req.targetValue;
        case MetricType.water:
          return water.todayTotalMl >= req.targetValue;
        case MetricType.workouts:
          return todayWorkouts >= req.targetValue;
        case MetricType.foodLogs:
          return todayMeals >= req.targetValue;
        case MetricType.manual:
          return _manualConfirmed;
        case MetricType.photoChallenge:
          return _manualConfirmed;
      }
    }

    String _metricValue(ChallengeRequirement req) {
      switch (req.metric) {
        case MetricType.steps:         return '${health.todaySteps ?? 0} steps';
        case MetricType.calories:      return '${food.totalCalories.round()} / ${food.dailyCalorieGoal.round()} kcal';
        case MetricType.protein:       return '${todayProtein.round()}g / ${profile.proteinGoalG}g protein';
        case MetricType.water:         return '${water.todayTotalMl}ml / ${req.targetValue.round()}ml';
        case MetricType.workouts:      return '$todayWorkouts workout(s) today';
        case MetricType.foodLogs:      return '$todayMeals entries logged today';
        case MetricType.manual:        return _manualConfirmed ? 'Confirmed ✓' : 'Tap to confirm';
        case MetricType.photoChallenge: return _manualConfirmed ? 'Photo submitted ✓' : 'Submit a photo to confirm';
      }
    }

    final allMet = def.requirements.every(_metricMet);
    final hasManual = def.requirements.any((r) => r.metric == MetricType.manual);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF3A4560), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Today's Check-In", style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(def.name, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            // Metric rows
            ...def.requirements.map((req) {
              final met = _metricMet(req);
              final isManual = req.metric == MetricType.manual;
              return GestureDetector(
                onTap: isManual ? () => setState(() => _manualConfirmed = !_manualConfirmed) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: met ? color.withValues(alpha: 0.1) : kCardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: met ? color.withValues(alpha: 0.4) : const Color(0xFF2A3550),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        met ? Icons.check_circle : (isManual ? Icons.radio_button_unchecked : Icons.radio_button_unchecked),
                        color: met ? color : kTextSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.label, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(_metricValue(req), style: TextStyle(color: met ? color : kTextSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (allMet || hasManual && _manualConfirmed)
                    ? () {
                        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                        final newDates = [...widget.uc.completedDates, todayStr];
                        final finished = ref.read(challengesProvider.notifier).checkInToday(def.id);
                        FirebaseService.updateCatalogCheckin(
                          def.id, newDates,
                          todaySteps: health.todaySteps,
                          todayCalories: food.totalCalories.round(),
                          todayWaterMl: water.todayTotalMl.toDouble(),
                          todayWorkouts: todayWorkouts,
                        );
                        Navigator.pop(context);
                        if (finished) {
                          _showCompletionDialog(context, def, color);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("${def.badgeEmoji} Check-in recorded!"),
                            backgroundColor: color,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allMet ? color : const Color(0xFF2A3550),
                  foregroundColor: allMet ? Colors.black : kTextSecondary,
                  disabledBackgroundColor: const Color(0xFF2A3550),
                  disabledForegroundColor: kTextSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  allMet ? 'Mark Complete ✓' : 'Goals Not Met Yet',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            if (!allMet && !hasManual) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                  final newDates = [...widget.uc.completedDates, todayStr];
                  ref.read(challengesProvider.notifier).checkInToday(def.id);
                  FirebaseService.updateCatalogCheckin(
                    def.id, newDates,
                    todaySteps: health.todaySteps,
                    todayCalories: food.totalCalories.round(),
                    todayWaterMl: water.todayTotalMl.toDouble(),
                    todayWorkouts: todayWorkouts,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("${def.badgeEmoji} Logged — keep pushing!"),
                    backgroundColor: const Color(0xFF2A3550),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Text('Log Anyway (Partial)', style: TextStyle(color: kTextSecondary, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showCompletionDialog(BuildContext context, ChallengeDefinition def, Color color) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: kSurfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(def.badgeEmoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Challenge Complete!', style: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(def.name, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'You earned the ${def.badgeName} badge. That\'s what slaying looks like.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Let\'s Go! 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
