import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/food_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/health_provider.dart';
import '../main.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(foodLogProvider);
    final profile = ref.watch(userProfileProvider);
    final activity = ref.watch(activityProvider);
    final weight = ref.watch(weightProvider);
    final water = ref.watch(waterProvider);
    final streak = ref.watch(streakProvider);
    final health = ref.watch(healthProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Row(
            children: [
              const Icon(Icons.bolt, color: kNeonYellow, size: 22),
              const SizedBox(width: 6),
              const Text('SLAYFIT',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 18,
                  )),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: kTextSecondary),
              onPressed: () {},
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _GreetingCard(weight: weight, profile: profile, streak: streak),
              const SizedBox(height: 16),
              _CalorieRingCard(food: food, activity: activity),
              const SizedBox(height: 16),
              _WaterCard(water: water),
              const SizedBox(height: 16),
              _MacrosCard(food: food, profile: profile),
              const SizedBox(height: 16),
              _TodayActivityCard(activity: activity),
              const SizedBox(height: 16),
              _StepsCard(health: health),
              const SizedBox(height: 16),
              _MealSummaryCard(food: food),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final WeightState weight;
  final UserProfile profile;
  final StreakState streak;
  const _GreetingCard({required this.weight, required this.profile, required this.streak});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final firstName = profile.name.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting, $firstName!',
                  style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Keep Slaying Today!',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          Row(
            children: [
              if (streak.currentStreak > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${streak.currentStreak}',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              if (weight.latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${weight.latest!.weightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: kNeonYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('current',
                          style: TextStyle(color: kTextSecondary, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieRingCard extends StatelessWidget {
  final FoodLogState food;
  final ActivityState activity;

  const _CalorieRingCard({required this.food, required this.activity});

  @override
  Widget build(BuildContext context) {
    final eaten = food.totalCalories;
    final goal = food.dailyCalorieGoal;
    final burned = activity.todayCaloriesBurned;
    final net = (eaten - burned).clamp(0, double.infinity);
    final remaining = (goal - net).clamp(0, goal);
    final progress = (net / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Calories',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 65,
                    sections: [
                      PieChartSectionData(
                        value: progress * 100,
                        color: progress >= 1.0 ? Colors.redAccent : kNeonYellow,
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - progress) * 100,
                        color: const Color(0xFF2A3550),
                        radius: 14,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remaining.toInt().toString(),
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('remaining',
                        style: TextStyle(color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingStat(
                  label: 'Eaten',
                  value: eaten.toInt().toString(),
                  color: kNeonYellow),
              _RingStat(
                  label: 'Burned',
                  value: burned.toInt().toString(),
                  color: Colors.greenAccent),
              _RingStat(
                  label: 'Goal',
                  value: goal.toInt().toString(),
                  color: kTextSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RingStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
        Text(label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _MacrosCard extends StatelessWidget {
  final FoodLogState food;
  final UserProfile profile;
  const _MacrosCard({required this.food, required this.profile});

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
          const Text('Macros',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 16),
          _MacroBar(
            label: 'Protein',
            current: food.totalProtein,
            goal: profile.proteinGoalG.toDouble(),
            color: const Color(0xFF60A5FA),
            unit: 'g',
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Carbs',
            current: food.totalCarbs,
            goal: profile.carbsGoalG.toDouble(),
            color: const Color(0xFFFBBF24),
            unit: 'g',
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Fat',
            current: food.totalFat,
            goal: profile.fatGoalG.toDouble(),
            color: const Color(0xFFF87171),
            unit: 'g',
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: kTextSecondary, fontSize: 13)),
            Text('${current.toInt()}/${goal.toInt()} $unit',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2A3550),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _TodayActivityCard extends StatelessWidget {
  final ActivityState activity;
  const _TodayActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activity Today',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${activity.todayCaloriesBurned.toInt()} kcal burned',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${activity.todayMinutes} min',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSummaryCard extends StatelessWidget {
  final FoodLogState food;
  const _MealSummaryCard({required this.food});

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
          const Text('Meals Today',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 12),
          _MealRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Breakfast',
            calories: food
                .entriesForMeal(MealType.breakfast)
                .fold(0.0, (s, e) => s + e.calories),
            color: const Color(0xFFFBBF24),
          ),
          _MealRow(
            icon: Icons.restaurant,
            label: 'Lunch',
            calories: food
                .entriesForMeal(MealType.lunch)
                .fold(0.0, (s, e) => s + e.calories),
            color: Colors.greenAccent,
          ),
          _MealRow(
            icon: Icons.nights_stay_outlined,
            label: 'Dinner',
            calories: food
                .entriesForMeal(MealType.dinner)
                .fold(0.0, (s, e) => s + e.calories),
            color: const Color(0xFF60A5FA),
          ),
          _MealRow(
            icon: Icons.cookie_outlined,
            label: 'Snacks',
            calories: food
                .entriesForMeal(MealType.snack)
                .fold(0.0, (s, e) => s + e.calories),
            color: const Color(0xFFF87171),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double calories;
  final Color color;

  const _MealRow({
    required this.icon,
    required this.label,
    required this.calories,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 13)),
          ),
          Text(
            calories > 0 ? '${calories.toInt()} kcal' : '—',
            style: TextStyle(
              color: calories > 0 ? kTextPrimary : kTextSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  final WaterState water;
  const _WaterCard({required this.water});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMl = water.todayTotalMl;
    final goalMl = water.dailyGoalMl;
    final progress = water.todayProgressPercent;

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
              const Row(
                children: [
                  Icon(Icons.water_drop, color: Color(0xFF60A5FA), size: 18),
                  SizedBox(width: 8),
                  Text('Water',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              Text('${(totalMl / 29.5735).round()}oz / ${(goalMl / 29.5735).round()}oz',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF2A3550),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WaterButton(label: '+8 oz', amountMl: 237, ref: ref),
              _WaterButton(label: '+12 oz', amountMl: 355, ref: ref),
              _WaterButton(label: '+16 oz', amountMl: 473, ref: ref),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends ConsumerWidget {
  final HealthState health;
  const _StepsCard({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const stepGoal = 10000;
    final steps = health.todaySteps;
    final progress = steps != null ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;

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
              const Row(
                children: [
                  Icon(Icons.directions_walk, color: Color(0xFF34D399), size: 18),
                  SizedBox(width: 8),
                  Text('Steps',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              if (!health.permissionsGranted)
                GestureDetector(
                  onTap: () => ref.read(healthProvider.notifier).requestPermissions(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                    ),
                    child: const Text('Connect',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                )
              else
                Text(
                  steps != null ? '$steps / $stepGoal' : '— / $stepGoal',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
            ],
          ),
          if (health.permissionsGranted) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF2A3550),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                minHeight: 8,
              ),
            ),
            if (health.latestWeightKg != null) ...[
              const SizedBox(height: 10),
              Text(
                'Scale: ${health.latestWeightKg!.toStringAsFixed(1)} kg',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Connect Health Connect to sync steps from Fitbit, Garmin, or your smart scale.',
              style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final int amountMl;
  final WidgetRef ref;
  const _WaterButton({required this.label, required this.amountMl, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ref.read(waterProvider.notifier).addWater(amountMl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
