import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/weight_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/measurements_provider.dart';
import 'body_scan_screen.dart';
import '../providers/records_provider.dart';
import '../providers/workout_provider.dart';
import '../main.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = ref.watch(weightProvider);
    final streak = ref.watch(streakProvider);
    final profile = ref.watch(userProfileProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Progress'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: kNeonYellow),
              onPressed: () => _shareProgress(weight, streak, profile),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WeightStatsRow(weight: weight),
              const SizedBox(height: 16),
              _BMICard(weight: weight, profile: profile),
              const SizedBox(height: 16),
              _WeightChartCard(weight: weight),
              const SizedBox(height: 16),
              _LogWeightButton(weight: weight),
              const SizedBox(height: 16),
              const _MeasurementsCard(),
              const SizedBox(height: 16),
              const _ProgressPhotosCard(),
              const SizedBox(height: 16),
              const _PersonalRecordsCard(),
              const SizedBox(height: 16),
              const _MuscleVolumeCard(),
              const SizedBox(height: 16),
              const _CalorieTrendCard(),
              const SizedBox(height: 16),
              const _WeeklyInsightsCard(),
              const SizedBox(height: 16),
              _ShareProgressButton(weight: weight, streak: streak, profile: profile),
            ]),
          ),
        ),
      ],
    );
  }

  void _shareProgress(
      WeightState weight, StreakState streak, UserProfile profile) {
    final name = profile.name.split(' ').first;
    final lines = <String>['🔥 $name\'s SlayFit Progress', ''];

    if (weight.latest != null) {
      final lbs = (weight.latest!.weightKg * 2.20462).toStringAsFixed(1);
      lines.add('⚖️  Current weight: $lbs lbs');
    }
    if (weight.totalLost != null && weight.totalLost! > 0.1) {
      final lostLbs = (weight.totalLost! * 2.20462).toStringAsFixed(1);
      lines.add('📉 Lost: $lostLbs lbs');
    }
    if (streak.currentStreak > 0) {
      lines.add('🔥 ${streak.currentStreak}-day logging streak');
    }
    lines.add('');
    lines.add('Tracked with SlayFit 💪');

    Share.share(lines.join('\n'));
  }
}

class _WeightStatsRow extends ConsumerWidget {
  final WeightState weight;
  const _WeightStatsRow({required this.weight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(userProfileProvider).useMetric;
    final lost = weight.totalLost;
    String fmt(double kg) => metric
        ? '${kg.toStringAsFixed(1)} kg'
        : '${(kg * 2.20462).toStringAsFixed(1)} lbs';
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Current',
            value: weight.latest != null ? fmt(weight.latest!.weightKg) : '—',
            color: kNeonYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Start',
            value: weight.startWeight != null ? fmt(weight.startWeight!) : '—',
            color: kTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Lost',
            value: lost != null ? fmt(lost.abs()) : '—',
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
        ],
      ),
    );
  }
}

class _WeightChartCard extends StatelessWidget {
  final WeightState weight;
  const _WeightChartCard({required this.weight});

  @override
  Widget build(BuildContext context) {
    if (weight.entries.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No weight data yet.\nLog your weight to see progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary)),
        ),
      );
    }

    final entries = weight.entries.length > 30
        ? weight.entries.sublist(weight.entries.length - 30)
        : weight.entries;

    final minY = entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 2;

    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weight Trend',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 4),
          Text('Last ${entries.length} entries',
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF2A3550),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kNeonYellow,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: kNeonYellow,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kNeonYellow.withValues(alpha: 0.2),
                          kNeonYellow.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogWeightButton extends ConsumerWidget {
  final WeightState weight;
  const _LogWeightButton({required this.weight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final metric = profile.useMetric;
    final latestDisplay = weight.latest != null
        ? metric
            ? '${weight.latest!.weightKg.toStringAsFixed(1)} kg'
            : '${(weight.latest!.weightKg * 2.20462).toStringAsFixed(1)} lbs'
        : null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: Text(latestDisplay != null
            ? 'Update Weight ($latestDisplay)'
            : 'Log Your Weight'),
        onPressed: () => _showLogDialog(context, ref, metric),
      ),
    );
  }

  void _showLogDialog(BuildContext context, WidgetRef ref, bool metric) {
    final current = weight.latest?.weightKg;
    final displayVal = current != null
        ? (metric ? current.toStringAsFixed(1) : (current * 2.20462).toStringAsFixed(1))
        : '';
    final controller = TextEditingController(text: displayVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Weight',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: kTextPrimary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: metric ? 'kg' : 'lbs',
            suffixStyle: const TextStyle(color: kTextSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                final kg = metric ? val : val / 2.20462;
                ref.read(weightProvider.notifier).logWeight(kg);
                // Auto water goal: 35 ml per kg body weight
                ref.read(waterProvider.notifier).setGoal((kg * 35).round());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _WeeklyInsightsCard extends ConsumerStatefulWidget {
  const _WeeklyInsightsCard();

  @override
  ConsumerState<_WeeklyInsightsCard> createState() =>
      _WeeklyInsightsCardState();
}

class _WeeklyInsightsCardState extends ConsumerState<_WeeklyInsightsCard> {
  bool _loaded = false;
  double _avgCalories = 0;
  double _avgProtein = 0;
  int _totalActiveMinutes = 0;
  int _daysHitGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider);
    final activity = ref.read(activityProvider);
    final goal = profile.dailyCalorieGoal.toDouble();

    double totalCalories = 0;
    double totalProtein = 0;
    int daysWithData = 0;
    int daysHit = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key =
          'food_log_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final json = prefs.getString(key);
      if (json != null) {
        final List list = jsonDecode(json);
        double dayCal = 0;
        double dayProtein = 0;
        for (final item in list) {
          dayCal += (item['calories'] as num).toDouble();
          dayProtein += (item['protein'] as num).toDouble();
        }
        if (dayCal > 0) {
          totalCalories += dayCal;
          totalProtein += dayProtein;
          daysWithData++;
          if (dayCal <= goal) daysHit++;
        }
      }
    }

    // Total active minutes from last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final activeMinutes = activity.entries
        .where((e) => e.loggedAt.isAfter(sevenDaysAgo))
        .fold(0, (s, e) => s + e.durationMinutes);

    if (mounted) {
      setState(() {
        _avgCalories = daysWithData > 0 ? totalCalories / daysWithData : 0;
        _avgProtein = daysWithData > 0 ? totalProtein / daysWithData : 0;
        _totalActiveMinutes = activeMinutes;
        _daysHitGoal = daysHit;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Insights',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Last 7 days',
              style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          if (!_loaded)
            const Center(
                child: CircularProgressIndicator(color: kNeonYellow))
          else ...[
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    label: 'Avg Calories',
                    value: '${_avgCalories.toInt()}',
                    unit: 'kcal',
                    color: kNeonYellow,
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightTile(
                    label: 'Avg Protein',
                    value: '${_avgProtein.toInt()}',
                    unit: 'g',
                    color: const Color(0xFF60A5FA),
                    icon: Icons.egg_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    label: 'Active Mins',
                    value: '$_totalActiveMinutes',
                    unit: 'min',
                    color: Colors.greenAccent,
                    icon: Icons.directions_run,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightTile(
                    label: 'Goal Days',
                    value: '$_daysHitGoal / 7',
                    unit: '',
                    color: Colors.orangeAccent,
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kNeonYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: kNeonYellow.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: kNeonYellow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildCallout(profile),
                      style: const TextStyle(
                          color: kTextPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildCallout(UserProfile profile) {
    if (_avgCalories == 0) return 'Start logging to see your weekly insights!';
    final proteinGoal = profile.proteinGoalG;
    if (_avgProtein >= proteinGoal) {
      return 'You hit your protein goal every day this week. Keep it up!';
    } else if (_daysHitGoal >= 5) {
      return 'You hit your calorie goal $_daysHitGoal/7 days. Great consistency!';
    } else if (_totalActiveMinutes >= 150) {
      return 'You logged $_totalActiveMinutes active minutes this week. WHO recommends 150 — nailed it!';
    } else {
      return 'You averaged ${_avgCalories.toInt()} kcal/day. Keep logging to track your trends!';
    }
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _InsightTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CalorieTrendCard extends ConsumerStatefulWidget {
  const _CalorieTrendCard();

  @override
  ConsumerState<_CalorieTrendCard> createState() => _CalorieTrendCardState();
}

class _CalorieTrendCardState extends ConsumerState<_CalorieTrendCard> {
  // Index 0 = 6 days ago, index 6 = today
  final List<double> _dailyCalories = List.filled(7, 0);
  final List<String> _dayLabels = List.filled(7, '');
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key =
          'food_log_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final json = prefs.getString(key);
      double dayCals = 0;
      if (json != null) {
        final List list = jsonDecode(json);
        for (final item in list) {
          dayCals += (item['calories'] as num).toDouble();
        }
      }
      final idx = 6 - i;
      _dailyCalories[idx] = dayCals;
      _dayLabels[idx] = _shortDay(date.weekday);
    }

    if (mounted) setState(() => _loaded = true);
  }

  String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _dailyCalories.reduce((a, b) => a > b ? a : b);
    final chartMax = (maxY < 500 ? 2000 : maxY * 1.3).ceilToDouble();
    final goal = ref.watch(userProfileProvider).dailyCalorieGoal.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('7-Day Calories',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              if (_loaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Goal: ${goal.toInt()} kcal',
                    style: const TextStyle(
                        color: kNeonYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_loaded)
            const SizedBox(
              height: 140,
              child: Center(
                  child: CircularProgressIndicator(color: kNeonYellow)),
            )
          else
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFF2A3550),
                      strokeWidth: 1,
                    ),
                    checkToShowHorizontalLine: (val) =>
                        val == goal || val == 0,
                    getDrawingVerticalLine: (_) => const FlLine(
                      color: Colors.transparent,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal,
                        color: kNeonYellow.withValues(alpha: 0.4),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) => Text(
                          _dayLabels[val.toInt()],
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  barGroups: _dailyCalories.asMap().entries.map((e) {
                    final isToday = e.key == 6;
                    final overGoal = e.value > goal && goal > 0;
                    final barColor = isToday
                        ? (overGoal ? Colors.redAccent : kNeonYellow)
                        : (e.value > 0
                            ? const Color(0xFF4A5568)
                            : const Color(0xFF2A3550));
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value > 0 ? e.value : 0,
                          color: barColor,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMax,
                            color: const Color(0xFF1A2235),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Share Progress Button ─────────────────────────────────────────────────────

class _ShareProgressButton extends StatelessWidget {
  final WeightState weight;
  final StreakState streak;
  final UserProfile profile;

  const _ShareProgressButton({
    required this.weight,
    required this.streak,
    required this.profile,
  });

  void _share() {
    final name = profile.name.split(' ').first;
    final lines = <String>['🔥 $name\'s SlayFit Progress', ''];

    if (weight.latest != null) {
      final lbs = (weight.latest!.weightKg * 2.20462).toStringAsFixed(1);
      lines.add('⚖️  Current weight: $lbs lbs');
    }
    if (weight.totalLost != null && weight.totalLost! > 0.1) {
      final lostLbs = (weight.totalLost! * 2.20462).toStringAsFixed(1);
      lines.add('📉 Lost: $lostLbs lbs');
    }
    if (streak.currentStreak > 0) {
      lines.add('🔥 ${streak.currentStreak}-day logging streak');
    }
    lines.add('');
    lines.add('Tracked with SlayFit 💪');

    Share.share(lines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _share,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kNeonYellow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text(
              'Share My Progress',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BMI Card ──────────────────────────────────────────────────────────────────

class _BMICard extends ConsumerWidget {
  final WeightState weight;
  final UserProfile profile;
  const _BMICard({required this.weight, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (weight.latest == null || profile.heightCm <= 0) {
      return const SizedBox.shrink();
    }
    final h = profile.heightCm / 100;
    final bmi = weight.latest!.weightKg / (h * h);
    final Color color;
    final String category;
    if (bmi < 18.5) {
      color = Colors.blueAccent;
      category = 'Underweight';
    } else if (bmi < 25) {
      color = Colors.greenAccent;
      category = 'Normal';
    } else if (bmi < 30) {
      color = kNeonYellow;
      category = 'Overweight';
    } else {
      color = Colors.redAccent;
      category = 'Obese';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(bmi.toStringAsFixed(1),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BMI',
                  style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(category,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const Spacer(),
          Text('Healthy: 18.5–24.9',
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Measurements Card ─────────────────────────────────────────────────────────

class _MeasurementsCard extends ConsumerWidget {
  const _MeasurementsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(measurementsProvider);
    final latest = m.latest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Body Measurements',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BodyScanScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kNeonYellow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kNeonYellow.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.document_scanner_outlined,
                              color: kNeonYellow, size: 14),
                          SizedBox(width: 4),
                          Text('Scan',
                              style: TextStyle(
                                  color: kNeonYellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showLogSheet(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3550),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: kTextSecondary, size: 14),
                          SizedBox(width: 4),
                          Text('Log',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (latest == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No measurements logged yet.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
            )
          else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (latest.waistCm != null)
                  _MeasTile(
                      label: 'Waist',
                      value: '${latest.waistCm!.toStringAsFixed(1)} cm'),
                if (latest.hipsCm != null)
                  _MeasTile(
                      label: 'Hips',
                      value: '${latest.hipsCm!.toStringAsFixed(1)} cm'),
                if (latest.chestCm != null)
                  _MeasTile(
                      label: 'Chest',
                      value: '${latest.chestCm!.toStringAsFixed(1)} cm'),
                if (latest.armsCm != null)
                  _MeasTile(
                      label: 'Arms',
                      value: '${latest.armsCm!.toStringAsFixed(1)} cm'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogMeasurementsSheet(ref: ref),
    );
  }
}

class _MeasTile extends StatelessWidget {
  final String label;
  final String value;
  const _MeasTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: kNeonYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LogMeasurementsSheet extends StatefulWidget {
  final WidgetRef ref;
  const _LogMeasurementsSheet({required this.ref});

  @override
  State<_LogMeasurementsSheet> createState() => _LogMeasurementsSheetState();
}

class _LogMeasurementsSheetState extends State<_LogMeasurementsSheet> {
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _chest = TextEditingController();
  final _arms = TextEditingController();
  final _bodyfat = TextEditingController();

  @override
  void dispose() {
    _waist.dispose();
    _hips.dispose();
    _chest.dispose();
    _arms.dispose();
    _bodyfat.dispose();
    super.dispose();
  }

  void _save() {
    final m = BodyMeasurement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      waistCm: double.tryParse(_waist.text),
      hipsCm: double.tryParse(_hips.text),
      chestCm: double.tryParse(_chest.text),
      armsCm: double.tryParse(_arms.text),
      bodyFatPercent: double.tryParse(_bodyfat.text),
    );
    widget.ref.read(measurementsProvider.notifier).addMeasurement(m);
    Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: Color(0xFF8A9BB8)),
            suffixText: label == 'Body Fat' ? '%' : 'cm',
            suffixStyle:
                const TextStyle(color: Color(0xFF8A9BB8)),
            filled: true,
            fillColor: const Color(0xFF1A2235),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Measurements',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 20),
          _field('Waist', _waist),
          _field('Hips', _hips),
          _field('Chest', _chest),
          _field('Arms', _arms),
          _field('Body Fat', _bodyfat),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Photos Card ──────────────────────────────────────────────────────

class _ProgressPhotosCard extends StatefulWidget {
  const _ProgressPhotosCard();

  @override
  State<_ProgressPhotosCard> createState() => _ProgressPhotosCardState();
}

class _ProgressPhotosCardState extends State<_ProgressPhotosCard> {
  List<String> _paths = [];
  static const _prefsKey = 'progress_photos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    setState(() => _paths = raw);
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return;
    final updated = [xfile.path, ..._paths];
    setState(() => _paths = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated);
  }

  Future<void> _removePhoto(int index) async {
    final updated = [..._paths]..removeAt(index);
    setState(() => _paths = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress Photos',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              GestureDetector(
                onTap: _addPhoto,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: kNeonYellow.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: kNeonYellow, size: 14),
                      SizedBox(width: 4),
                      Text('Add Photo',
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
          if (_paths.isEmpty)
            const Text('Tap "Add Photo" to track your transformation.',
                style: TextStyle(color: kTextSecondary, fontSize: 13))
          else
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final file = File(_paths[i]);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              _PhotoFullScreen(path: _paths[i])),
                    ),
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: kSurfaceDark,
                          title: const Text('Remove photo?',
                              style: TextStyle(color: Colors.white)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Remove',
                                    style: TextStyle(
                                        color: Colors.redAccent))),
                          ],
                        ),
                      );
                      if (ok == true) _removePhoto(i);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: kCardDark,
                                child: const Icon(Icons.broken_image,
                                    color: kTextSecondary),
                              )),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoFullScreen extends StatelessWidget {
  final String path;
  const _PhotoFullScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}

// ── Personal Records Card ─────────────────────────────────────────────────────

class _PersonalRecordsCard extends ConsumerWidget {
  const _PersonalRecordsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    if (records.isEmpty) return const SizedBox.shrink();

    final top = records.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: kNeonYellow, size: 18),
              SizedBox(width: 8),
              Text('Personal Records',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...top.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.exerciseName,
                          style: const TextStyle(
                              color: kTextPrimary, fontSize: 13)),
                    ),
                    if (r.maxWeightKg != null)
                      Text('${r.maxWeightKg!.toStringAsFixed(1)} kg × ${r.maxReps}',
                          style: const TextStyle(
                              color: kNeonYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))
                    else
                      Text('${r.maxReps} reps',
                          style: const TextStyle(
                              color: kNeonYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Muscle Volume Card ────────────────────────────────────────────────────────

// Maps keywords in exercise names to muscle groups
String _muscleGroup(String exerciseName) {
  final name = exerciseName.toLowerCase();
  if (name.contains('push') || name.contains('chest') || name.contains('bench') || name.contains('dip')) return 'Chest';
  if (name.contains('squat') || name.contains('lunge') || name.contains('glute') || name.contains('leg') || name.contains('deadlift') || name.contains('hip')) return 'Legs';
  if (name.contains('row') || name.contains('pull') || name.contains('superman') || name.contains('back')) return 'Back';
  if (name.contains('press') || name.contains('shoulder') || name.contains('overhead')) return 'Shoulders';
  if (name.contains('curl') || name.contains('tricep') || name.contains('bicep') || name.contains('arm')) return 'Arms';
  if (name.contains('plank') || name.contains('crunch') || name.contains('ab') || name.contains('core') || name.contains('mountain') || name.contains('dead bug') || name.contains('v-up') || name.contains('boat')) return 'Core';
  if (name.contains('jack') || name.contains('burpee') || name.contains('high knee') || name.contains('jog') || name.contains('run') || name.contains('skater') || name.contains('cardio')) return 'Cardio';
  return 'Other';
}

class _MuscleVolumeCard extends ConsumerWidget {
  const _MuscleVolumeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutProvider).history;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final Map<String, int> sets = {};
    for (final session in history) {
      if (session.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        for (final ex in session.exercises) {
          final group = _muscleGroup(ex.name);
          sets[group] = (sets[group] ?? 0) + ex.sets.length;
        }
      }
    }

    if (sets.isEmpty) return const SizedBox.shrink();

    const order = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Other'];
    final groups = order.where((g) => sets.containsKey(g)).toList();
    final maxSets = sets.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week\'s Training',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSets + 2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFF2A3550), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= groups.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(groups[i].substring(0, 3),
                              style: const TextStyle(
                                  color: kTextSecondary, fontSize: 9)),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                ),
                barGroups: groups.asMap().entries.map((e) {
                  final count = sets[e.value]!.toDouble();
                  final isTop = count == maxSets;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: isTop ? kNeonYellow : kNeonYellow.withValues(alpha: 0.35),
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxSets + 2,
                          color: const Color(0xFF1A2235),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
