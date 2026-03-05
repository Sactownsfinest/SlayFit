import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_provider.dart';
import '../main.dart';

class FoodLogScreen extends ConsumerWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(foodLogProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Food Log'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${food.totalCalories.toInt()} / ${food.dailyCalorieGoal.toInt()} kcal',
                  style: const TextStyle(
                    color: kNeonYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MealSection(
                mealType: MealType.breakfast,
                icon: Icons.wb_sunny_outlined,
                color: const Color(0xFFFBBF24),
                food: food,
              ),
              const SizedBox(height: 12),
              _MealSection(
                mealType: MealType.lunch,
                icon: Icons.restaurant,
                color: Colors.greenAccent,
                food: food,
              ),
              const SizedBox(height: 12),
              _MealSection(
                mealType: MealType.dinner,
                icon: Icons.nights_stay_outlined,
                color: const Color(0xFF60A5FA),
                food: food,
              ),
              const SizedBox(height: 12),
              _MealSection(
                mealType: MealType.snack,
                icon: Icons.cookie_outlined,
                color: const Color(0xFFF87171),
                food: food,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final IconData icon;
  final Color color;
  final FoodLogState food;

  const _MealSection({
    required this.mealType,
    required this.icon,
    required this.color,
    required this.food,
  });

  String get _mealName {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snacks';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = food.entriesForMeal(mealType);
    final mealCalories = entries.fold(0.0, (s, e) => s + e.calories);

    return Container(
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  _mealName,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (mealCalories > 0)
                  Text(
                    '${mealCalories.toInt()} kcal',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFF2A3550)),
            ...entries.map((entry) => _FoodEntryTile(entry: entry)),
          ],
          const Divider(height: 1, color: Color(0xFF2A3550)),
          InkWell(
            onTap: () => _showAddFoodSheet(context, ref, mealType),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('Add food',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodSheet(
      BuildContext context, WidgetRef ref, MealType meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFoodSheet(meal: meal),
    );
  }
}

class _FoodEntryTile extends ConsumerWidget {
  final FoodEntry entry;
  const _FoodEntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha:0.3),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) =>
          ref.read(foodLogProvider.notifier).removeEntry(entry.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.servingSize.toInt()} ${entry.servingUnit} · P: ${entry.protein.toInt()}g  C: ${entry.carbs.toInt()}g  F: ${entry.fat.toInt()}g',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.calories.toInt()}',
              style: const TextStyle(
                  color: kNeonYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(width: 4),
            const Text('kcal',
                style: TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  final MealType meal;
  const _AddFoodSheet({required this.meal});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingController = TextEditingController(text: '100');

  // Quick-add common foods
  static const _quickFoods = [
    {'name': 'Chicken Breast', 'cal': 165, 'p': 31, 'c': 0, 'f': 4},
    {'name': 'Brown Rice', 'cal': 215, 'p': 5, 'c': 45, 'f': 2},
    {'name': 'Egg (1 large)', 'cal': 70, 'p': 6, 'c': 0, 'f': 5},
    {'name': 'Banana', 'cal': 89, 'p': 1, 'c': 23, 'f': 0},
    {'name': 'Greek Yogurt', 'cal': 59, 'p': 10, 'c': 4, 'f': 0},
    {'name': 'Oatmeal', 'cal': 150, 'p': 5, 'c': 27, 'f': 3},
    {'name': 'Salmon', 'cal': 208, 'p': 20, 'c': 0, 'f': 13},
    {'name': 'Avocado', 'cal': 160, 'p': 2, 'c': 9, 'f': 15},
  ];

  void _fillQuickFood(Map<String, dynamic> food) {
    _nameController.text = food['name'] as String;
    _caloriesController.text = food['cal'].toString();
    _proteinController.text = food['p'].toString();
    _carbsController.text = food['c'].toString();
    _fatController.text = food['f'].toString();
    _servingController.text = '1';
    setState(() {});
  }

  void _submit() {
    final name = _nameController.text.trim();
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    if (name.isEmpty || calories <= 0) return;

    ref.read(foodLogProvider.notifier).addEntry(FoodEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          calories: calories,
          protein: double.tryParse(_proteinController.text) ?? 0,
          carbs: double.tryParse(_carbsController.text) ?? 0,
          fat: double.tryParse(_fatController.text) ?? 0,
          servingSize: double.tryParse(_servingController.text) ?? 1,
          servingUnit: 'serving',
          meal: widget.meal,
          loggedAt: DateTime.now(),
        ));
    Navigator.of(context).pop();
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
                const Text('Add Food',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Quick Add',
                style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickFoods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _fillQuickFood(_quickFoods[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kNeonYellow.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kNeonYellow.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      _quickFoods[i]['name'] as String,
                      style: const TextStyle(
                          color: kNeonYellow, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _InputField(
                controller: _nameController,
                label: 'Food name',
                keyboardType: TextInputType.text),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _caloriesController,
                    label: 'Calories',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _servingController,
                    label: 'Serving',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                      controller: _proteinController,
                      label: 'Protein (g)',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InputField(
                      controller: _carbsController,
                      label: 'Carbs (g)',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InputField(
                      controller: _fatController,
                      label: 'Fat (g)',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Add to Log'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}
