import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );
    if (result == null || !mounted) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$result.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'] as Map<String, dynamic>;
          final n = (product['nutriments'] as Map?) ?? {};
          _nameController.text = product['product_name'] ?? 'Unknown';
          _caloriesController.text =
              ((n['energy-kcal_100g'] ?? n['energy-kcal'] ?? 0) as num)
                  .toStringAsFixed(0);
          _proteinController.text =
              ((n['proteins_100g'] ?? 0) as num).toStringAsFixed(1);
          _carbsController.text =
              ((n['carbohydrates_100g'] ?? 0) as num).toStringAsFixed(1);
          _fatController.text =
              ((n['fat_100g'] ?? 0) as num).toStringAsFixed(1);
          _servingController.text = '100';
          setState(() {});
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product not found in database')),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to look up barcode')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchFood(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&json=1&page_size=8'
        '&fields=product_name,nutriments',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List?) ?? [];
        setState(() {
          _searchResults = products
              .where((p) =>
                  p['product_name'] != null &&
                  (p['product_name'] as String).isNotEmpty)
              .map<Map<String, dynamic>>((p) {
            final n = (p['nutriments'] as Map?) ?? {};
            return {
              'name': p['product_name'] as String,
              'cal': ((n['energy-kcal_100g'] ?? n['energy-kcal'] ?? 0) as num)
                  .toDouble(),
              'p': ((n['proteins_100g'] ?? 0) as num).toDouble(),
              'c': ((n['carbohydrates_100g'] ?? 0) as num).toDouble(),
              'f': ((n['fat_100g'] ?? 0) as num).toDouble(),
            };
          }).toList();
        });
      }
    } catch (_) {
      // Silently fail on network error
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

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
            // Search bar + barcode button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search food database...',
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: kNeonYellow),
                              ),
                            )
                          : const Icon(Icons.search, color: kTextSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: kTextSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => _searchFood(v),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _scanBarcode,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A3550)),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: kNeonYellow, size: 24),
                  ),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3550)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF2A3550)),
                  itemBuilder: (_, i) {
                    final food = _searchResults[i];
                    return InkWell(
                      onTap: () {
                        _nameController.text = food['name'] as String;
                        _caloriesController.text =
                            (food['cal'] as double).toStringAsFixed(0);
                        _proteinController.text =
                            (food['p'] as double).toStringAsFixed(1);
                        _carbsController.text =
                            (food['c'] as double).toStringAsFixed(1);
                        _fatController.text =
                            (food['f'] as double).toStringAsFixed(1);
                        _servingController.text = '100';
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                food['name'] as String,
                                style: const TextStyle(
                                    color: kTextPrimary, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(food['cal'] as double).toStringAsFixed(0)} kcal/100g',
                              style: const TextStyle(
                                  color: kNeonYellow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _TemplatesSection(meal: widget.meal),
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

class _TemplatesSection extends ConsumerWidget {
  final MealType meal;
  const _TemplatesSection({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(foodLogProvider).templates;
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Templates',
            style: TextStyle(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        ...templates.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A3550)),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(t.name,
                      style: const TextStyle(
                          color: kTextPrimary, fontSize: 13)),
                  subtitle: Text('${t.items.length} items',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline,
                            color: kNeonYellow, size: 22),
                        onPressed: () {
                          ref
                              .read(foodLogProvider.notifier)
                              .applyTemplate(t, meal);
                          Navigator.of(context).pop();
                        },
                        tooltip: 'Apply template',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => ref
                            .read(foodLogProvider.notifier)
                            .deleteTemplate(t.id),
                        tooltip: 'Delete template',
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                Navigator.of(context).pop(barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: kNeonYellow, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at product barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
