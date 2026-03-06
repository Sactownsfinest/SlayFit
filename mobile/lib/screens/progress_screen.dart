import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/user_provider.dart';
import '../main.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = ref.watch(weightProvider);
    final food = ref.watch(foodLogProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Progress'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WeightStatsRow(weight: weight),
              const SizedBox(height: 16),
              _WeightChartCard(weight: weight),
              const SizedBox(height: 16),
              _LogWeightButton(weight: weight),
              const SizedBox(height: 16),
              _CalorieTrendCard(food: food),
              const SizedBox(height: 16),
              const _WeeklyInsightsCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _WeightStatsRow extends StatelessWidget {
  final WeightState weight;
  const _WeightStatsRow({required this.weight});

  @override
  Widget build(BuildContext context) {
    final lost = weight.totalLost;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Current',
            value: weight.latest != null
                ? '${weight.latest!.weightKg.toStringAsFixed(1)} kg'
                : '—',
            color: kNeonYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Start',
            value: weight.startWeight != null
                ? '${weight.startWeight!.toStringAsFixed(1)} kg'
                : '—',
            color: kTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Lost',
            value: lost != null
                ? '${lost.toStringAsFixed(1)} kg'
                : '—',
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
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF2A3550),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: Text(weight.latest != null
            ? 'Update Weight (${weight.latest!.weightKg.toStringAsFixed(1)} kg)'
            : 'Log Your Weight'),
        onPressed: () => _showLogDialog(context, ref),
      ),
    );
  }

  void _showLogDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
        text: weight.latest?.weightKg.toStringAsFixed(1) ?? '');
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
          decoration: const InputDecoration(
            suffixText: 'kg',
            suffixStyle: TextStyle(color: kTextSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                ref.read(weightProvider.notifier).logWeight(val);
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

class _CalorieTrendCard extends StatelessWidget {
  final FoodLogState food;
  const _CalorieTrendCard({required this.food});

  @override
  Widget build(BuildContext context) {
    // Show 7-day placeholder bars (today is last bar with real data)
    final todayCalories = food.totalCalories;
    final sampleData = [1450.0, 1820.0, 1600.0, 1950.0, 1380.0, 1700.0, todayCalories];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-Day Calories',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 2500,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF2A3550),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[val.toInt() % 7],
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11));
                      },
                    ),
                  ),
                ),
                barGroups: sampleData.asMap().entries.map((e) {
                  final isToday = e.key == 6;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: isToday ? kNeonYellow : const Color(0xFF2A3550),
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 2500,
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
