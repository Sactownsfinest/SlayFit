import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: kNeonYellow,
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, color: kNeonYellow, size: 24),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('SLAYFIT',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 18,
                      )),
                  Text('By Shennel',
                      style: TextStyle(
                        color: kNeonYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      )),
                ],
              ),
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
              _CalorieRingCard(food: food, activity: activity, health: health),
              const SizedBox(height: 16),
              _WaterCard(water: water),
              const SizedBox(height: 16),
              _MacrosCard(food: food, profile: profile),
              const SizedBox(height: 16),
              _TodayActivityCard(activity: activity, health: health),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2E48), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting, $firstName!',
              style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Keep Slaying Today!',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              if (streak.currentStreak > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${streak.currentStreak} day streak',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              if (weight.latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kNeonYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kNeonYellow.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${(weight.latest!.weightKg * 2.20462).toStringAsFixed(1)} lbs',
                    style: const TextStyle(
                      color: kNeonYellow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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
  final HealthState health;

  const _CalorieRingCard({required this.food, required this.activity, required this.health});

  @override
  Widget build(BuildContext context) {
    final eaten = food.totalCalories;
    final goal = food.dailyCalorieGoal;
    final fitbitBurned = health.permissionsGranted ? (health.todayCaloriesBurned ?? 0) : 0;
    final burned = fitbitBurned > 0 ? fitbitBurned.toDouble() : activity.todayCaloriesBurned;
    final deficit = burned - eaten;
    final isDeficit = deficit > 0;
    final netLabel = isDeficit ? '${deficit.abs().toInt()}' : '${deficit.abs().toInt()}';
    final statusLabel = isDeficit ? 'deficit' : deficit == 0 ? 'on track' : 'surplus';
    final statusColor = isDeficit ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C2A42), Color(0xFF0F1826)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kNeonYellow.withValues(alpha: 0.07),
            blurRadius: 24,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: kNeonYellow.withValues(alpha: 0.08),
          width: 1,
        ),
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
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _DualCalorieRingPainter(
                    eaten: eaten,
                    burned: burned,
                    goal: goal,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      netLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'goal: ${goal.toInt()} kcal',
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
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
                color: const Color(0xFFF87171),
                dot: true,
              ),
              _RingStat(
                label: 'Burned',
                value: burned.toInt().toString(),
                color: const Color(0xFF4ADE80),
                dot: true,
              ),
              _RingStat(
                label: 'Goal',
                value: goal.toInt().toString(),
                color: kTextSecondary,
                dot: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualCalorieRingPainter extends CustomPainter {
  final double eaten;
  final double burned;
  final double goal;

  const _DualCalorieRingPainter({
    required this.eaten,
    required this.burned,
    required this.goal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (very faint guide ring)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1E2D45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3,
    );

    // Burned arc — green LED, counter-clockwise from top
    final burnedSweep = (burned / goal).clamp(0.0, 1.0) * 2 * math.pi;
    if (burnedSweep > 0) {
      _drawLedArc(canvas, rect, -math.pi / 2, -burnedSweep,
          const Color(0xFF4ADE80), strokeWidth);
    }

    // Eaten arc — red LED, clockwise from top
    final eatenSweep = (eaten / goal).clamp(0.0, 1.0) * 2 * math.pi;
    if (eatenSweep > 0) {
      _drawLedArc(canvas, rect, -math.pi / 2, eatenSweep,
          const Color(0xFFF87171), strokeWidth);
    }
  }

  static void _drawLedArc(Canvas canvas, Rect rect, double startAngle,
      double sweepAngle, Color color, double strokeWidth) {
    // Outer diffuse halo (widest, faintest)
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = color.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 3.4
          ..strokeCap = StrokeCap.round);
    // Mid halo
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2.0
          ..strokeCap = StrokeCap.round);
    // Inner glow corona
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = color.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.15
          ..strokeCap = StrokeCap.round);
    // Core bright tube (thin)
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.28
          ..strokeCap = StrokeCap.round);
    // Specular hot-spot (white center line)
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.10
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_DualCalorieRingPainter old) =>
      old.eaten != eaten || old.burned != burned || old.goal != goal;
}

class _RingStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool dot;

  const _RingStat({
    required this.label,
    required this.value,
    required this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
            ],
            Text(value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
          ],
        ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2B40), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              // Track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2640),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              // Glow layer
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              // Core LED bar
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Specular highlight strip
              FractionallySizedBox(
                widthFactor: progress,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayActivityCard extends StatelessWidget {
  final ActivityState activity;
  final HealthState health;
  const _TodayActivityCard({required this.activity, required this.health});

  @override
  Widget build(BuildContext context) {
    // Prefer Fitbit data when connected; fall back to manually logged activity
    final calories = health.permissionsGranted && (health.todayCaloriesBurned ?? 0) > 0
        ? health.todayCaloriesBurned!
        : activity.todayCaloriesBurned.toInt();
    final minutes = health.permissionsGranted && (health.todayActiveMinutes ?? 0) > 0
        ? health.todayActiveMinutes!
        : activity.todayMinutes;
    final source = health.permissionsGranted ? 'Fitbit' : 'Logged';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E3A), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
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
                Text('Activity Today · $source',
                    style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal burned',
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
            '$minutes min',
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2B3E), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B42), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Container(height: 12, color: const Color(0xFF1A2640)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.55),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
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

  static const _green = Color(0xFF34D399);

  void _showManualDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(
        text: health.todaySteps != null ? health.todaySteps.toString() : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Log Steps', style: TextStyle(color: kTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
            labelText: 'Steps today',
            hintText: 'e.g. 7500',
            suffixText: 'steps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 0) {
                ref.read(healthProvider.notifier).logManualSteps(v);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow, foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const stepGoal = 10000;
    final steps = health.todaySteps;
    final progress = steps != null ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;
    final miles = steps != null ? (steps / 2000.0) : null;
    final source = health.stepSource;

    String sourceLabel() {
      switch (source) {
        case StepSource.fitbit:
          return health.isLoading ? 'Fitbit · Syncing…' : 'Fitbit';
        case StepSource.googleFit:
          return 'Google Fit';
        case StepSource.pedometer:
          return 'Phone sensor · Live';
        case StepSource.manual:
          return 'Manual';
        case StepSource.none:
          return '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3028), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34D399).withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.directions_walk, color: _green, size: 18),
                SizedBox(width: 8),
                Text('Steps',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ]),
              Text(
                steps != null ? '$steps / $stepGoal' : '— / $stepGoal',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Container(height: 12, color: const Color(0xFF1A2640)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF34D399)]),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.55),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Miles row
          Row(children: [
            const Icon(Icons.straighten, color: kTextSecondary, size: 13),
            const SizedBox(width: 4),
            Text(
              miles != null
                  ? '${miles.toStringAsFixed(2)} mi · ${(miles * 1.60934).toStringAsFixed(2)} km'
                  : '— mi',
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ]),
          // Source badge
          if (source != StepSource.none) ...[
            const SizedBox(height: 4),
            Text(sourceLabel(),
                style: const TextStyle(color: _green, fontSize: 11)),
          ],

          // ── Fitbit controls ──────────────────────────────────────────────
          if (health.permissionsGranted) ...[
            if (health.latestWeightKg != null) ...[
              const SizedBox(height: 8),
              Text(
                'Scale: ${(health.latestWeightKg! * 2.20462).toStringAsFixed(1)} lbs',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (health.errorMessage != null)
                Expanded(
                    child: Text(health.errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 11)))
              else
                const Text('Fitbit connected',
                    style: TextStyle(color: _green, fontSize: 11)),
              GestureDetector(
                onTap: health.errorMessage != null &&
                        health.errorMessage!.contains('expired')
                    ? () => ref
                        .read(healthProvider.notifier)
                        .requestPermissions()
                    : () => ref.read(healthProvider.notifier).fetchData(),
                child: Text(
                  health.errorMessage != null &&
                          health.errorMessage!.contains('expired')
                      ? 'Reconnect'
                      : 'Sync now',
                  style: const TextStyle(
                      color: _green, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ]),

          // ── Google Fit controls ─────────────────────────────────────────
          ] else if (health.googleFitConnected) ...[
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Google Fit connected',
                  style: TextStyle(color: _green, fontSize: 11)),
              GestureDetector(
                onTap: () =>
                    ref.read(healthProvider.notifier).fetchGoogleFitData(),
                child: const Text('Sync now',
                    style: TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),

          // ── Pedometer controls ──────────────────────────────────────────
          ] else if (health.pedometerActive) ...[
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Phone sensor active',
                  style: TextStyle(color: _green, fontSize: 11)),
              GestureDetector(
                onTap: () =>
                    ref.read(healthProvider.notifier).disconnectPedometer(),
                child: const Text('Disable',
                    style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),

          // ── Not connected — show options ────────────────────────────────
          ] else ...[
            const SizedBox(height: 12),
            const Text('Choose a step source:',
                style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // 1. Phone Pedometer — real-time
            _SourceOption(
              icon: Icons.phone_android,
              label: 'Phone Pedometer',
              sublabel: 'Real-time · no account needed',
              onTap: () =>
                  ref.read(healthProvider.notifier).connectPedometer(),
            ),
            const SizedBox(height: 6),

            // 2. Google Fit
            _SourceOption(
              icon: Icons.directions_run,
              label: 'Google Fit',
              sublabel: 'Also works for Samsung Health (enable sync in Samsung Health → Connected Services)',
              onTap: () =>
                  ref.read(healthProvider.notifier).connectGoogleFit(),
            ),
            const SizedBox(height: 6),

            // 3. Fitbit
            _SourceOption(
              icon: Icons.watch_outlined,
              label: 'Fitbit',
              sublabel: 'Requires Fitbit account',
              onTap: () =>
                  ref.read(healthProvider.notifier).requestPermissions(),
            ),
            const SizedBox(height: 6),

            // 4. Manual
            _SourceOption(
              icon: Icons.edit_outlined,
              label: steps != null ? 'Update manually' : 'Enter manually',
              sublabel: 'Type today\'s step count',
              onTap: () => _showManualDialog(context, ref),
            ),

            if (health.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(health.errorMessage!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 11, height: 1.3)),
            ],
          ],
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF34D399).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF34D399), size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(sublabel,
                      style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 11,
                          height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF34D399), size: 18),
          ],
        ),
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
