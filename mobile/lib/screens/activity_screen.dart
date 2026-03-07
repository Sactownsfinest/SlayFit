import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/activity_provider.dart';
import '../providers/records_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../data/workout_library.dart';
import '../services/youtube_service.dart';
import '../services/workout_ai_service.dart';
import '../main.dart';

// ── Root Screen ─────────────────────────────────────────────────────────────

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          floating: true,
          snap: true,
          forceElevated: innerBoxIsScrolled,
          title: const Text('Activity'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: kNeonYellow,
            labelColor: kNeonYellow,
            unselectedLabelColor: kTextSecondary,
            tabs: const [Tab(text: 'Log'), Tab(text: 'Workouts')],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => _tabController.index == 0
                    ? _showLogActivitySheet(context)
                    : _showCreatePlanSheet(context),
                icon: const Icon(Icons.add, color: kNeonYellow, size: 18),
                label: const Text('New',
                    style: TextStyle(
                        color: kNeonYellow, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(onLogTap: () => _showLogActivitySheet(context)),
          const _WorkoutsTab(),
        ],
      ),
    );
  }

  void _showLogActivitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LogActivitySheet(),
    );
  }

  void _showCreatePlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreatePlanSheet(),
    );
  }
}

// ── Log Tab ─────────────────────────────────────────────────────────────────

class _LogTab extends ConsumerWidget {
  final VoidCallback onLogTap;
  const _LogTab({required this.onLogTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _TodaySummaryCard(activity: activity),
        const SizedBox(height: 16),
        if (activity.todayEntries.isNotEmpty) ...[
          const Text('Today',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 12),
          ...activity.todayEntries.map((e) => _ActivityEntryTile(entry: e)),
          const SizedBox(height: 16),
        ],
        _QuickLogSection(onLogTap: onLogTap),
      ],
    );
  }
}

// ── Workouts Tab ─────────────────────────────────────────────────────────────

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // AI Personal Plan
        const _AiWorkoutPlanCard(),
        // Recent sessions
        if (workout.recentSessions.isNotEmpty) ...[
          const Text('Recent Sessions',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          ...workout.recentSessions.map((s) => _SessionTile(session: s)),
          const SizedBox(height: 20),
        ],
        // My Plans
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Plans',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (workout.plans.isNotEmpty)
              GestureDetector(
                onTap: () => _showCreatePlanSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: kNeonYellow, size: 14),
                      SizedBox(width: 4),
                      Text('New Plan',
                          style: TextStyle(
                              color: kNeonYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (workout.plans.isEmpty)
          _EmptyPlansHint(onTap: () => _showCreatePlanSheet(context))
        else
          ...workout.plans.map((plan) => _PlanCard(plan: plan)),
        const SizedBox(height: 20),
        // ── Library ──────────────────────────────────────────────────────
        const Text('Workout Library',
            style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Tap a plan to preview and add it to My Plans.',
            style: TextStyle(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        _LibraryDurationCard(
          label: '5-Minute',
          subtitle: 'Quick moves, anytime',
          icon: Icons.bolt,
          color: const Color(0xFFFBBF24),
          plans: kLibrary5Min,
        ),
        const SizedBox(height: 10),
        _LibraryDurationCard(
          label: '10-Minute',
          subtitle: 'Easy & light workouts',
          icon: Icons.directions_walk,
          color: Colors.greenAccent,
          plans: kLibrary10Min,
        ),
        const SizedBox(height: 10),
        _LibraryDurationCard(
          label: '30-Minute',
          subtitle: 'Solid full-body sessions',
          icon: Icons.fitness_center,
          color: kNeonYellow,
          plans: kLibrary30Min,
        ),
        const SizedBox(height: 10),
        _LibraryDurationCard(
          label: '60-Minute',
          subtitle: 'Complete challenge workouts',
          icon: Icons.local_fire_department,
          color: Colors.orangeAccent,
          plans: kLibrary60Min,
        ),
      ],
    );
  }

  void _showCreatePlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreatePlanSheet(),
    );
  }
}

class _EmptyWorkoutsState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyWorkoutsState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kNeonYellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center,
                  color: kNeonYellow, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('No Workout Plans Yet',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Create a plan with exercises, sets, and reps. Then start a session to track your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create First Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlansHint extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPlansHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: kNeonYellow.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: kNeonYellow, size: 20),
            SizedBox(width: 12),
            Text('Create a workout plan',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── AI Workout Plan Card ──────────────────────────────────────────────────────

class _AiWorkoutPlanCard extends ConsumerStatefulWidget {
  const _AiWorkoutPlanCard();

  @override
  ConsumerState<_AiWorkoutPlanCard> createState() => _AiWorkoutPlanCardState();
}

class _AiWorkoutPlanCardState extends ConsumerState<_AiWorkoutPlanCard> {
  AiWorkoutPlan? _plan;
  bool _loading = false;
  String? _error;
  YoutubePlayerController? _videoController;
  bool _loadingVideo = false;

  static const _prefKey = 'ai_workout_plan_v1';

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final plan = AiWorkoutPlan.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      final today = DateTime.now();
      if (plan.generatedAt.year == today.year &&
          plan.generatedAt.month == today.month &&
          plan.generatedAt.day == today.day) {
        if (mounted) {
          setState(() => _plan = plan);
          _fetchVideo(plan.youtubeQuery, plan.durationMinutes);
        }
      }
    } catch (_) {}
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = ref.read(userProfileProvider);
      final weight = ref.read(weightProvider);
      final plan = await WorkoutAiService.generatePlan(
        userName: profile.name,
        currentWeightKg: weight.entries.isNotEmpty
            ? weight.entries.last.weightKg
            : null,
        goalWeightKg: weight.goalWeightKg,
        dailyCalorieGoal: profile.dailyCalorieGoal,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(plan.toJson()));
      if (mounted) {
        setState(() {
          _plan = plan;
          _loading = false;
        });
        _fetchVideo(plan.youtubeQuery, plan.durationMinutes);
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        setState(() {
          _loading = false;
          if (raw.contains('429') || raw.contains('quota') ||
              raw.contains('RESOURCE_EXHAUSTED')) {
            _error = 'AI quota reached. Try again in a few minutes.';
          } else {
            _error = 'Could not generate plan. Please try again.';
          }
        });
      }
    }
  }

  Future<void> _fetchVideo(String query, int durationMinutes) async {
    setState(() => _loadingVideo = true);
    final videoId = await YouTubeService.searchVideoId(query,
        durationMinutes: durationMinutes);
    if (!mounted) return;
    setState(() {
      _loadingVideo = false;
      if (videoId != null) {
        _videoController?.dispose();
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeonYellow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: kNeonYellow, size: 18),
              const SizedBox(width: 8),
              const Text('AI Personal Plan',
                  style: TextStyle(
                      color: kNeonYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              if (_plan != null && !_loading)
                GestureDetector(
                  onTap: _generate,
                  child: const Text('Regenerate',
                      style:
                          TextStyle(color: kTextSecondary, fontSize: 12)),
                ),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(
                child: CircularProgressIndicator(color: kNeonYellow)),
            const SizedBox(height: 8),
            const Center(
                child: Text('Building your plan...',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 13))),
            const SizedBox(height: 12),
          ] else if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black),
              child: const Text('Try Again'),
            ),
          ] else if (_plan == null) ...[
            const SizedBox(height: 8),
            const Text(
                'Get a workout built specifically for your weight goal.',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generate My Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(_plan!.name,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 2),
            Text(
                '${_plan!.focus} · ${_plan!.durationMinutes} min · ~${_plan!.estimatedCalories} kcal',
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            ..._plan!.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: kNeonYellow, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(ex.name,
                              style: const TextStyle(
                                  color: kTextPrimary, fontSize: 13))),
                      Text('${ex.sets}×${ex.reps}',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            if (_loadingVideo)
              Container(
                height: 180,
                decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10)),
                child: const Center(
                    child: CircularProgressIndicator(color: kNeonYellow)),
              )
            else if (_videoController != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: YoutubePlayer(
                  controller: _videoController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: kNeonYellow,
                ),
              )
            else
              Container(
                height: 56,
                alignment: Alignment.center,
                child: const Text('No matching video found',
                    style: TextStyle(
                        color: kTextSecondary, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Library Duration Card ─────────────────────────────────────────────────────

class _LibraryDurationCard extends ConsumerWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<LibraryPlan> plans;

  const _LibraryDurationCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.plans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLibrarySheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text('${plans.length} plans',
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: kTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLibrarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LibraryPlanListSheet(
        durationLabel: label,
        plans: plans,
        accentColor: color,
      ),
    );
  }
}

// ── Library Plan List Sheet ───────────────────────────────────────────────────

class _LibraryPlanListSheet extends StatelessWidget {
  final String durationLabel;
  final List<LibraryPlan> plans;
  final Color accentColor;

  const _LibraryPlanListSheet({
    required this.durationLabel,
    required this.plans,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3550),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('$durationLabel Workouts',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: plans.length,
              itemBuilder: (_, i) => _LibraryPlanTile(
                plan: plans[i],
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Library Plan Tile ─────────────────────────────────────────────────────────

class _LibraryPlanTile extends ConsumerWidget {
  final LibraryPlan plan;
  final Color accentColor;

  const _LibraryPlanTile({
    required this.plan,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alreadyAdded = ref
        .watch(workoutProvider)
        .plans
        .any((p) => p.id == plan.plan.id);

    return GestureDetector(
      onTap: () => _showPreview(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3550)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(plan.difficulty,
                                style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${plan.plan.exercises.length} exercises · ${plan.plan.totalSets} sets',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (alreadyAdded)
                  const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 20)
                else
                  const Icon(Icons.chevron_right,
                      color: kTextSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.description,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LibraryPlanPreviewSheet(
        plan: plan,
        accentColor: accentColor,
      ),
    );
  }
}

// ── Library Plan Preview Sheet ────────────────────────────────────────────────

class _LibraryPlanPreviewSheet extends ConsumerStatefulWidget {
  final LibraryPlan plan;
  final Color accentColor;

  const _LibraryPlanPreviewSheet({
    required this.plan,
    required this.accentColor,
  });

  @override
  ConsumerState<_LibraryPlanPreviewSheet> createState() =>
      _LibraryPlanPreviewSheetState();
}

class _LibraryPlanPreviewSheetState
    extends ConsumerState<_LibraryPlanPreviewSheet> {
  YoutubePlayerController? _videoController;
  bool _loadingVideo = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final videoId = await YouTubeService.searchVideoId(
        widget.plan.videoQuery,
        durationMinutes: widget.plan.durationMinutes);
    if (!mounted) return;
    setState(() {
      if (videoId != null) {
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
            disableDragSeek: false,
          ),
        );
      }
      _loadingVideo = false;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alreadyAdded = ref
        .watch(workoutProvider)
        .plans
        .any((p) => p.id == widget.plan.plan.id);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3550),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.plan.name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(
                        '${widget.plan.durationMinutes} min · ${widget.plan.difficulty}',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(widget.plan.description,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 10),
          // ── Guided Video ──────────────────────────────────────────────────
          if (_loadingVideo)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: kNeonYellow),
                    SizedBox(height: 10),
                    Text('Loading guided video...',
                        style:
                            TextStyle(color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
            )
          else if (_videoController != null)
            YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _videoController!,
                showVideoProgressIndicator: true,
                progressColors: const ProgressBarColors(
                  playedColor: kNeonYellow,
                  handleColor: kNeonYellow,
                ),
              ),
              builder: (ctx, player) => player,
            )
          else
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('No video available offline',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 12)),
              ),
            ),
          const Divider(color: Color(0xFF2A3550), height: 24),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.plan.plan.exercises.length,
              itemBuilder: (_, i) {
                final ex = widget.plan.plan.exercises[i];
                final sets = ex.sets.length;
                final reps = ex.sets.isNotEmpty ? ex.sets.first.reps : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(ex.name,
                            style: const TextStyle(
                                color: kTextPrimary, fontSize: 13)),
                      ),
                      Text(
                        '$sets × $reps',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: alreadyAdded
                    ? null
                    : () {
                        ref
                            .read(workoutProvider.notifier)
                            .savePlan(widget.plan.plan);
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: kCardDark,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.greenAccent, size: 18),
                                const SizedBox(width: 8),
                                Text('"${widget.plan.name}" added to My Plans',
                                    style: const TextStyle(
                                        color: kTextPrimary)),
                              ],
                            ),
                          ),
                        );
                      },
                icon: Icon(
                    alreadyAdded ? Icons.check : Icons.add, size: 18),
                label: Text(
                    alreadyAdded ? 'Already in My Plans' : 'Add to My Plans'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  final WorkoutPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: kSurfaceDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Plan?',
                style: TextStyle(color: kTextPrimary)),
            content: Text('Delete "${plan.name}"?',
                style: const TextStyle(color: kTextSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: kTextSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(workoutProvider.notifier).deletePlan(plan.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3550)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: kNeonYellow, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'} · ${plan.totalSets} sets',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (plan.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plan.exercises.take(4).map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3550),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(e.name,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11)),
                  );
                }).toList()
                  ..addAll(plan.exercises.length > 4
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A3550),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('+${plan.exercises.length - 4} more',
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 11)),
                          )
                        ]
                      : []),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditPlanSheet(context, plan),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextSecondary,
                      side: const BorderSide(color: Color(0xFF2A3550)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: plan.exercises.isEmpty
                        ? null
                        : () => _showStartWorkoutSheet(context, plan),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanSheet(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreatePlanSheet(existing: plan),
    );
  }

  void _showStartWorkoutSheet(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StartWorkoutSheet(plan: plan),
    );
  }
}

// ── Session Tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(session.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.planName,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('$dateStr · ${session.exercises.length} exercises · ${session.totalSets} sets',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text('${session.durationMinutes} min',
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Create / Edit Plan Sheet ───────────────────────────────────────────────────

class _CreatePlanSheet extends ConsumerStatefulWidget {
  final WorkoutPlan? existing;
  const _CreatePlanSheet({this.existing});

  @override
  ConsumerState<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<_CreatePlanSheet> {
  late TextEditingController _nameCtrl;
  late List<WorkoutExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _exercises = List.from(widget.existing?.exercises ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (ctx) => _AddExerciseDialog(),
    );
    if (result != null) {
      setState(() => _exercises.add(result));
    }
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(workoutProvider.notifier);
    final plan = widget.existing != null
        ? WorkoutPlan(
            id: widget.existing!.id,
            name: name,
            exercises: _exercises,
            createdAt: widget.existing!.createdAt,
          )
        : notifier.newPlan(name).copyWith(exercises: _exercises);

    notifier.savePlan(plan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3550),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existing != null ? 'Edit Plan' : 'New Workout Plan',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: kTextPrimary),
                decoration: const InputDecoration(
                  labelText: 'Plan name',
                  hintText: 'e.g. Push Day, Full Body...',
                ),
                autofocus: widget.existing == null,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercises (${_exercises.length})',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add, size: 16, color: kNeonYellow),
                    label: const Text('Add',
                        style: TextStyle(
                            color: kNeonYellow, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _exercises.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No exercises yet. Tap Add to start.',
                          style:
                              TextStyle(color: kTextSecondary, fontSize: 13)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _exercises.length,
                      itemBuilder: (_, i) {
                        final ex = _exercises[i];
                        final sets = ex.sets.length;
                        final reps = ex.sets.isNotEmpty ? ex.sets.first.reps : 0;
                        final weight = ex.sets.isNotEmpty
                            ? ex.sets.first.weightKg
                            : null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: kCardDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex.name,
                                        style: const TextStyle(
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                      '$sets × $reps reps${weight != null ? ' @ ${(weight * 2.20462).toStringAsFixed(0)} lbs' : ''}',
                                      style: const TextStyle(
                                          color: kTextSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: kTextSecondary, size: 18),
                                onPressed: () => _removeExercise(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameCtrl.text.trim().isNotEmpty ? _save : null,
                  child: Text(widget.existing != null ? 'Save Changes' : 'Create Plan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Exercise Dialog ────────────────────────────────────────────────────────

class _AddExerciseDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddExerciseDialog> createState() =>
      _AddExerciseDialogState();
}

class _AddExerciseDialogState extends ConsumerState<_AddExerciseDialog> {
  final _nameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Exercise',
          style:
              TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                  labelText: 'Exercise name',
                  hintText: 'e.g. Bench Press'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextPrimary),
                    decoration:
                        const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextPrimary),
                    decoration:
                        const InputDecoration(labelText: 'Reps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                  labelText: 'Weight (optional)',
                  suffixText: 'lbs'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: kTextSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final sets = int.tryParse(_setsCtrl.text) ?? 3;
            final reps = int.tryParse(_repsCtrl.text) ?? 10;
            final weightLbs = double.tryParse(_weightCtrl.text);
            final weightKg =
                weightLbs != null ? weightLbs / 2.20462 : null;
            if (name.isEmpty) return;
            final exercise = ref
                .read(workoutProvider.notifier)
                .newExercise(name, sets, reps, weightKg: weightKg);
            Navigator.pop(context, exercise);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Start Workout Sheet ────────────────────────────────────────────────────────

class _StartWorkoutSheet extends ConsumerStatefulWidget {
  final WorkoutPlan plan;
  const _StartWorkoutSheet({required this.plan});

  @override
  ConsumerState<_StartWorkoutSheet> createState() =>
      _StartWorkoutSheetState();
}

class _StartWorkoutSheetState extends ConsumerState<_StartWorkoutSheet> {
  late Timer _timer;
  int _elapsed = 0; // seconds
  final Set<String> _completedSets = {}; // 'exerciseId_setIndex'
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _elapsedStr {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _finish() {
    final duration = (_elapsed / 60).ceil().clamp(1, 999);
    final session = ref.read(workoutProvider.notifier).newSession(
          widget.plan,
          widget.plan.exercises,
          duration,
        );
    ref.read(workoutProvider.notifier).logSession(session);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kCardDark,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Text('Workout logged! $duration min',
                style: const TextStyle(color: kTextPrimary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = widget.plan.totalSets;
    final completedCount = _completedSets.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3550),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.plan.name,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Row(
                      children: [
                        const Icon(Icons.timer, color: kNeonYellow, size: 14),
                        const SizedBox(width: 4),
                        Text(_elapsedStr,
                            style: const TextStyle(
                                color: kNeonYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(width: 12),
                        Text('$completedCount/$totalSets sets',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalSets > 0 ? completedCount / totalSets : 0,
                backgroundColor: const Color(0xFF2A3550),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 6,
              ),
            ),
          ),
          // Exercise list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              itemCount: widget.plan.exercises.length,
              itemBuilder: (_, ei) {
                final ex = widget.plan.exercises[ei];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 10),
                      ...ex.sets.asMap().entries.map((entry) {
                        final si = entry.key;
                        final set = entry.value;
                        final key = '${ex.id}_$si';
                        final done = _completedSets.contains(key);
                        final weight = set.weightKg != null
                            ? ' @ ${(set.weightKg! * 2.20462).toStringAsFixed(0)} lbs'
                            : '';
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (done) {
                                _completedSets.remove(key);
                              } else {
                                _completedSets.add(key);
                              }
                            });
                            if (!done) {
                              final isNewPR = ref
                                  .read(recordsProvider.notifier)
                                  .checkAndUpdate(ex.name, set.reps,
                                      set.weightKg, DateTime.now());
                              if (isNewPR) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🏆 New PR! Best ${ex.name} ever',
                                      style: const TextStyle(
                                          color: Color(0xFF0A0E1A),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: kNeonYellow,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: done
                                  ? Colors.greenAccent.withValues(alpha: 0.12)
                                  : const Color(0xFF2A3550),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: done
                                    ? Colors.greenAccent.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: done
                                      ? Colors.greenAccent
                                      : kTextSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Set ${si + 1} · ${set.reps} reps$weight',
                                  style: TextStyle(
                                    color:
                                        done ? Colors.greenAccent : kTextPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          // Finish button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.check, size: 18),
                label: Text(completedCount == totalSets && totalSets > 0
                    ? 'Finish Workout 🎉'
                    : 'Finish Workout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Existing Log Widgets (unchanged) ──────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final ActivityState activity;
  const _TodaySummaryCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNeonYellow.withValues(alpha: 0.15),
            Colors.greenAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeonYellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(
            icon: Icons.local_fire_department,
            value: '${activity.todayCaloriesBurned.toInt()}',
            unit: 'kcal',
            label: 'Burned',
            color: kNeonYellow,
          ),
          Container(width: 1, height: 50, color: const Color(0xFF2A3550)),
          _SummaryItem(
            icon: Icons.timer_outlined,
            value: '${activity.todayMinutes}',
            unit: 'min',
            label: 'Active',
            color: Colors.greenAccent,
          ),
          Container(width: 1, height: 50, color: const Color(0xFF2A3550)),
          _SummaryItem(
            icon: Icons.fitness_center,
            value: '${activity.todayEntries.length}',
            unit: '',
            label: 'Workouts',
            color: const Color(0xFF60A5FA),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
        Text(label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ActivityEntryTile extends ConsumerWidget {
  final ActivityEntry entry;
  const _ActivityEntryTile({required this.entry});

  Color get _categoryColor {
    switch (entry.category) {
      case ActivityCategory.cardio:
        return Colors.greenAccent;
      case ActivityCategory.strength:
        return const Color(0xFF60A5FA);
      case ActivityCategory.flexibility:
        return const Color(0xFFA78BFA);
      case ActivityCategory.sports:
        return const Color(0xFFFBBF24);
      case ActivityCategory.other:
        return kTextSecondary;
    }
  }

  IconData get _categoryIcon {
    switch (entry.category) {
      case ActivityCategory.cardio:
        return Icons.directions_run;
      case ActivityCategory.strength:
        return Icons.fitness_center;
      case ActivityCategory.flexibility:
        return Icons.self_improvement;
      case ActivityCategory.sports:
        return Icons.sports;
      case ActivityCategory.other:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) =>
          ref.read(activityProvider.notifier).removeEntry(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon, color: _categoryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text('${entry.durationMinutes} min',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.caloriesBurned.toInt()}',
                    style: const TextStyle(
                      color: kNeonYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                const Text('kcal',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogSection extends ConsumerWidget {
  final VoidCallback onLogTap;
  const _QuickLogSection({required this.onLogTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Log',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: kCommonActivities.map((a) {
            return GestureDetector(
              onTap: () => _showQuickLogDialog(context, ref, a),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3550)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForCategory(
                          a['category'] as ActivityCategory),
                      color: kNeonYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a['name'] as String,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconForCategory(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.cardio:
        return Icons.directions_run;
      case ActivityCategory.strength:
        return Icons.fitness_center;
      case ActivityCategory.flexibility:
        return Icons.self_improvement;
      case ActivityCategory.sports:
        return Icons.sports;
      case ActivityCategory.other:
        return Icons.star_outline;
    }
  }

  void _showQuickLogDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic> activity) {
    final durationController = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final duration =
              int.tryParse(durationController.text) ?? 30;
          final cals =
              ((activity['calsPerMin'] as double) * duration).toInt();
          return AlertDialog(
            backgroundColor: kSurfaceDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(activity['name'] as String,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Duration (minutes)',
                    style: TextStyle(color: kTextSecondary)),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                  decoration:
                      const InputDecoration(suffixText: 'min'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text('≈ $cals kcal burned',
                    style: const TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: kTextSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final dur =
                      int.tryParse(durationController.text) ?? 30;
                  ref.read(activityProvider.notifier).logActivity(
                        name: activity['name'] as String,
                        category:
                            activity['category'] as ActivityCategory,
                        durationMinutes: dur,
                        caloriesBurned:
                            (activity['calsPerMin'] as double) * dur,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Log It'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogActivitySheet extends ConsumerStatefulWidget {
  const _LogActivitySheet();

  @override
  ConsumerState<_LogActivitySheet> createState() =>
      _LogActivitySheetState();
}

class _LogActivitySheetState extends ConsumerState<_LogActivitySheet> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController();
  ActivityCategory _category = ActivityCategory.cardio;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Activity',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: kTextPrimary),
              decoration:
                  const InputDecoration(labelText: 'Activity name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityCategory>(
              initialValue: _category,
              dropdownColor: kCardDark,
              style: const TextStyle(color: kTextPrimary),
              decoration:
                  const InputDecoration(labelText: 'Category'),
              items: ActivityCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                            c.name[0].toUpperCase() + c.name.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Duration',
                        suffixText: 'min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Calories',
                        suffixText: 'kcal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Activity'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text) ?? 0;
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    if (name.isEmpty || duration <= 0) return;

    ref.read(activityProvider.notifier).logActivity(
          name: name,
          category: _category,
          durationMinutes: duration,
          caloriesBurned: calories,
        );
    Navigator.pop(context);
  }
}

// ── WorkoutPlan.copyWith extension ────────────────────────────────────────────
extension WorkoutPlanX on WorkoutPlan {
  WorkoutPlan copyWith(
          {String? name,
          List<WorkoutExercise>? exercises,
          DateTime? createdAt}) =>
      WorkoutPlan(
        id: id,
        name: name ?? this.name,
        exercises: exercises ?? this.exercises,
        createdAt: createdAt ?? this.createdAt,
      );
}
