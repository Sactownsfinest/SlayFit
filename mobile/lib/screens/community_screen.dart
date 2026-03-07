import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../providers/activity_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/food_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
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
          tabs: const [
            Tab(text: 'Challenges'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: !_initialized
          ? _buildInitFailed()
          : TabBarView(
              controller: _tab,
              children: [
                _ChallengesTab(displayName: _displayName),
                _LeaderboardTab(),
                _ChatTab(displayName: _displayName),
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
          const Text('Community features require\nan internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary)),
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

// ── Challenges Tab ────────────────────────────────────────────────────────────

class _ChallengesTab extends ConsumerStatefulWidget {
  final String displayName;
  const _ChallengesTab({required this.displayName});

  @override
  ConsumerState<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<_ChallengesTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SlayChallenge>>(
      stream: FirebaseService.myChallengesStream(),
      builder: (context, snap) {
        final challenges = snap.data ?? [];
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black),
            child: const Text('Done'),
          ),
        ],
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

  const _ChallengeCard({
    required this.challenge,
    required this.ref,
    required this.onSync,
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kNeonYellow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: kNeonYellow.withValues(alpha: 0.3)),
                ),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: challenge.joinCode));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text('Code copied! Share with friends.'),
                    ));
                  },
                  child: Text(
                    challenge.joinCode,
                    style: const TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync, size: 14),
              label: const Text('Sync My Score'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kNeonYellow,
                side:
                    BorderSide(color: kNeonYellow.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
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
  bool _sending = false;

  @override
  void dispose() {
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
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle:
                        const TextStyle(color: kTextSecondary),
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
