import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';
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
