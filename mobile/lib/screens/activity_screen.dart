import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activity_provider.dart';
import '../main.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Activity'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => _showLogActivitySheet(context, ref),
                icon: const Icon(Icons.add, color: kNeonYellow, size: 18),
                label: const Text('Log',
                    style: TextStyle(
                        color: kNeonYellow, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                ...activity.todayEntries.map(
                  (e) => _ActivityEntryTile(entry: e),
                ),
                const SizedBox(height: 16),
              ],
              _QuickLogSection(),
            ]),
          ),
        ),
      ],
    );
  }

  void _showLogActivitySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LogActivitySheet(),
    );
  }
}

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
              onTap: () => _showQuickLogDialog(
                  context, ref, a),
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
                  decoration: const InputDecoration(suffixText: 'min'),
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
              decoration: const InputDecoration(labelText: 'Activity name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityCategory>(
              initialValue: _category,
              dropdownColor: kCardDark,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(labelText: 'Category'),
              items: ActivityCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
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
                        labelText: 'Duration', suffixText: 'min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Calories', suffixText: 'kcal'),
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
