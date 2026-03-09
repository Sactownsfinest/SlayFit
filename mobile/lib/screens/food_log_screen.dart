import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/food_provider.dart';
import '../providers/recipe_provider.dart';
import '../main.dart';
import 'grocery_list_screen.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodLogProvider);

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Food'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: kNeonYellow),
              tooltip: 'Meal Plan & Grocery List',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryListScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: kNeonYellow),
              tooltip: 'Scan your plate',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: kSurfaceDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const _FoodScanSheet(),
              ),
            ),
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: kNeonYellow,
            unselectedLabelColor: kTextSecondary,
            indicatorColor: kNeonYellow,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Log'),
              Tab(text: 'Favorites'),
              Tab(text: 'Recipes'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _FoodLogTab(food: food),
          const _FavoritesTab(),
          const _RecipesTab(),
        ],
      ),
    );
  }
}

// ── Food Log Tab ──────────────────────────────────────────────────────────────

class _FoodLogTab extends ConsumerWidget {
  final FoodLogState food;
  const _FoodLogTab({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
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
                if (entries.isNotEmpty) ...[
                  Text(
                    '${mealCalories.toInt()} kcal',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showSaveTemplateDialog(context, ref, entries),
                    child: Tooltip(
                      message: 'Save meal as template',
                      child: Icon(Icons.bookmark_add_outlined, color: color, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFF2A3550)),
            ...entries.map((entry) => _FoodEntryTile(entry: entry, mealColor: color)),
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

  void _showSaveTemplateDialog(
      BuildContext context, WidgetRef ref, List<FoodEntry> entries) {
    final ctrl = TextEditingController(text: _mealName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        title: const Text('Save as Template',
            style: TextStyle(color: kTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(foodLogProvider.notifier).saveAsTemplate(name, entries);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$name" saved as template')),
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(color: kNeonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryTile extends ConsumerWidget {
  final FoodEntry entry;
  final Color mealColor;
  const _FoodEntryTile({required this.entry, required this.mealColor});

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditFoodSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.horizontal,
      // Swipe right → edit (blue), swipe left → delete (red)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
        child: const Icon(Icons.edit_outlined, color: Color(0xFF60A5FA)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.3),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showEditSheet(context);
          return false; // Don't actually dismiss — just open edit sheet
        }
        return true; // Allow left swipe to dismiss (delete)
      },
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
                      '${entry.servingSize.toStringAsFixed(1)} ${entry.servingUnit} · P: ${entry.protein.toInt()}g  C: ${entry.carbs.toInt()}g  F: ${entry.fat.toInt()}g',
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
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
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => ref
                    .read(favoriteFoodsProvider.notifier)
                    .toggle(entry),
                child: Icon(
                  ref.watch(favoriteFoodsProvider).any((f) =>
                          f.name.toLowerCase() ==
                          entry.name.toLowerCase())
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: ref.watch(favoriteFoodsProvider).any((f) =>
                          f.name.toLowerCase() ==
                          entry.name.toLowerCase())
                      ? kNeonYellow
                      : kTextSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
    );
  }
}

class _EditFoodSheet extends ConsumerStatefulWidget {
  final FoodEntry entry;
  const _EditFoodSheet({required this.entry});

  @override
  ConsumerState<_EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends ConsumerState<_EditFoodSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _protCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _servingCtrl;

  double _baseCal = 0, _baseProt = 0, _baseCarbs = 0, _baseFat = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final s = e.servingSize > 0 ? e.servingSize : 1.0;
    _baseCal = e.calories / s;
    _baseProt = e.protein / s;
    _baseCarbs = e.carbs / s;
    _baseFat = e.fat / s;
    _nameCtrl = TextEditingController(text: e.name);
    _calCtrl = TextEditingController(text: e.calories.toStringAsFixed(0));
    _protCtrl = TextEditingController(text: e.protein.toStringAsFixed(1));
    _carbsCtrl = TextEditingController(text: e.carbs.toStringAsFixed(1));
    _fatCtrl = TextEditingController(text: e.fat.toStringAsFixed(1));
    _servingCtrl = TextEditingController(text: s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1));
    _servingCtrl.addListener(_onServingChanged);
  }

  void _onServingChanged() {
    if (_baseCal == 0) return;
    final s = double.tryParse(_servingCtrl.text) ?? 1;
    if (s <= 0) return;
    setState(() {
      _calCtrl.text = (_baseCal * s).toStringAsFixed(0);
      _protCtrl.text = (_baseProt * s).toStringAsFixed(1);
      _carbsCtrl.text = (_baseCarbs * s).toStringAsFixed(1);
      _fatCtrl.text = (_baseFat * s).toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _servingCtrl.removeListener(_onServingChanged);
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(foodLogProvider.notifier).updateEntry(
      FoodEntry(
        id: widget.entry.id,
        name: name,
        calories: double.tryParse(_calCtrl.text) ?? widget.entry.calories,
        protein: double.tryParse(_protCtrl.text) ?? widget.entry.protein,
        carbs: double.tryParse(_carbsCtrl.text) ?? widget.entry.carbs,
        fat: double.tryParse(_fatCtrl.text) ?? widget.entry.fat,
        servingSize: double.tryParse(_servingCtrl.text) ?? widget.entry.servingSize,
        servingUnit: widget.entry.servingUnit,
        meal: widget.entry.meal,
        loggedAt: widget.entry.loggedAt,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Food',
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
            const SizedBox(height: 16),
            _InputField(controller: _nameCtrl, label: 'Food name', keyboardType: TextInputType.text),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InputField(controller: _calCtrl, label: 'Calories', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _InputField(controller: _servingCtrl, label: 'Serving', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InputField(controller: _protCtrl, label: 'Protein (g)', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _InputField(controller: _carbsCtrl, label: 'Carbs (g)', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _InputField(controller: _fatCtrl, label: 'Fat (g)', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 8),
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
  final _servingController = TextEditingController(text: '1');
  final _searchController = TextEditingController();

  // Base macros for 1 serving — recalculated when serving count changes
  double _baseCal = 0, _baseProt = 0, _baseCarbs = 0, _baseFat = 0;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _servingController.addListener(_onServingChanged);
  }

  void _onServingChanged() {
    if (_baseCal == 0) return;
    final servings = double.tryParse(_servingController.text) ?? 1;
    if (servings <= 0) return;
    _caloriesController.text = ((_baseCal * servings) * 10).roundToDouble() / 10 == (_baseCal * servings).roundToDouble()
        ? (_baseCal * servings).toStringAsFixed(0)
        : (_baseCal * servings).toStringAsFixed(1);
    _proteinController.text = (_baseProt * servings).toStringAsFixed(1);
    _carbsController.text = (_baseCarbs * servings).toStringAsFixed(1);
    _fatController.text = (_baseFat * servings).toStringAsFixed(1);
  }

  void _setBaseValues(double cal, double prot, double carbs, double fat) {
    _baseCal = cal;
    _baseProt = prot;
    _baseCarbs = carbs;
    _baseFat = fat;
    _caloriesController.text = cal.toStringAsFixed(0);
    _proteinController.text = prot.toStringAsFixed(1);
    _carbsController.text = carbs.toStringAsFixed(1);
    _fatController.text = fat.toStringAsFixed(1);
    _servingController.text = '1';
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _searchFood(value));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _servingController.removeListener(_onServingChanged);
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
          // Use per-serving values if available, otherwise per-100g
          final hasSrv = n.containsKey('energy-kcal_serving');
          final cal = ((hasSrv ? n['energy-kcal_serving'] : n['energy-kcal_100g']) ?? n['energy-kcal'] ?? 0 as num).toDouble();
          final prot = ((hasSrv ? n['proteins_serving'] : n['proteins_100g']) ?? 0 as num).toDouble();
          final carbs = ((hasSrv ? n['carbohydrates_serving'] : n['carbohydrates_100g']) ?? 0 as num).toDouble();
          final fat = ((hasSrv ? n['fat_serving'] : n['fat_100g']) ?? 0 as num).toDouble();
          _setBaseValues(cal, prot, carbs, fat);
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
      // USDA FoodData Central — returns clean, accurate results for common foods
      final uri = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search'
        '?query=${Uri.encodeComponent(query.trim())}'
        '&pageSize=10'
        '&dataType=Foundation,SR%20Legacy,Branded'
        '&api_key=ksmVttTD7HULBghripcKmMyao7wzpzOd72swy5Kl',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foods = (data['foods'] as List?) ?? [];
        setState(() {
          _searchResults = foods.map<Map<String, dynamic>>((f) {
            final nutrients = (f['foodNutrients'] as List?) ?? [];
            double getN(int id) =>
                (nutrients.firstWhere((n) => n['nutrientId'] == id,
                        orElse: () => {})['value'] as num?)
                    ?.toDouble() ??
                0;
            return {
              'name': f['description'] as String? ?? '',
              'cal': getN(1008),
              'p': getN(1003),
              'c': getN(1005),
              'f': getN(1004),
            };
          }).where((f) => (f['name'] as String).isNotEmpty).take(10).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
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
    _setBaseValues(
      (food['cal'] as num).toDouble(),
      (food['p'] as num).toDouble(),
      (food['c'] as num).toDouble(),
      (food['f'] as num).toDouble(),
    );
    setState(() {});
  }

  void _submit() {
    final name = _nameController.text.trim();
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name')),
      );
      return;
    }

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
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom),
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
                    onChanged: _onSearchChanged,
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
                        _setBaseValues(
                          food['cal'] as double,
                          food['p'] as double,
                          food['c'] as double,
                          food['f'] as double,
                        );
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
                              '${(food['cal'] as double).toStringAsFixed(0)} kcal/srv',
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
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(barcode!.rawValue);
  }

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
            controller: _controller,
            onDetect: _onDetect,
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

// ── Recipes Tab ───────────────────────────────────────────────────────────────

class _RecipesTab extends ConsumerWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeState = ref.watch(recipeProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Recipes',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: kSurfaceDark,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _CreateRecipeSheet(ref: ref),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kNeonYellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: kNeonYellow, size: 14),
                    SizedBox(width: 4),
                    Text('New Recipe',
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
        const SizedBox(height: 16),
        if (recipeState.recipes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kNeonYellow.withValues(alpha: 0.15)),
            ),
            child: const Column(
              children: [
                Icon(Icons.menu_book_outlined, color: kNeonYellow, size: 36),
                SizedBox(height: 12),
                Text('No recipes yet',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text('Tap "New Recipe" to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ...recipeState.recipes.map((r) => _RecipeTile(recipe: r, ref: ref)),
      ],
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final WidgetRef ref;
  const _RecipeTile({required this.recipe, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) =>
          ref.read(recipeProvider.notifier).deleteRecipe(recipe.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3550)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.caloriesPerServing.toInt()} kcal · P ${recipe.proteinPerServing.toStringAsFixed(0)}g · C ${recipe.carbsPerServing.toStringAsFixed(0)}g · F ${recipe.fatPerServing.toStringAsFixed(0)}g per serving',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: kTextSecondary, size: 20),
              tooltip: 'Edit recipe',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: kSurfaceDark,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _EditRecipeSheet(recipe: recipe, ref: ref),
              ),
            ),
            ElevatedButton(
              onPressed: () => _showLogDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Log',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    int servings = 1;
    MealType meal = MealType.lunch;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kSurfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Log ${recipe.name}',
              style: const TextStyle(color: kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Servings',
                      style: TextStyle(color: kTextSecondary)),
                  Row(children: [
                    IconButton(
                      onPressed: () =>
                          setS(() => servings = (servings - 1).clamp(1, 20)),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: kTextSecondary),
                    ),
                    Text('$servings',
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    IconButton(
                      onPressed: () =>
                          setS(() => servings = (servings + 1).clamp(1, 20)),
                      icon: const Icon(Icons.add_circle_outline,
                          color: kNeonYellow),
                    ),
                  ]),
                ],
              ),
              DropdownButtonFormField<MealType>(
                initialValue: meal,
                dropdownColor: kSurfaceDark,
                style: const TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Meal',
                  labelStyle: const TextStyle(color: kTextSecondary),
                  filled: true,
                  fillColor: kCardDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
                items: MealType.values
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name[0].toUpperCase() +
                            m.name.substring(1))))
                    .toList(),
                onChanged: (v) => setS(() => meal = v!),
              ),
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
                ref
                    .read(recipeProvider.notifier)
                    .logRecipe(recipe, servings, meal);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: kCardDark,
                    content: Text(
                        '${recipe.name} logged!',
                        style: const TextStyle(color: kTextPrimary)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black),
              child: const Text('Log',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Recipe Sheet ───────────────────────────────────────────────────────

class _CreateRecipeSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateRecipeSheet({required this.ref});

  @override
  State<_CreateRecipeSheet> createState() => _CreateRecipeSheetState();
}

class _CreateRecipeSheetState extends State<_CreateRecipeSheet> {
  final _nameCtrl = TextEditingController();
  int _servings = 1;
  final List<RecipeIngredient> _ingredients = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Ingredient search via USDA ──────────────────────────────────────────────

  void _addIngredient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _IngredientSearchSheet(
        onAdded: (ing) => setState(() => _ingredients.add(ing)),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _ingredients.isEmpty) return;
    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      servings: _servings,
      ingredients: _ingredients,
    );
    widget.ref.read(recipeProvider.notifier).saveRecipe(recipe);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalCal =
        _ingredients.fold(0.0, (s, i) => s + i.calories);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFF2A3550),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Recipe',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: kTextSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Recipe Name',
                      labelStyle:
                          const TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kCardDark,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Servings:',
                          style:
                              TextStyle(color: kTextSecondary)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() =>
                            _servings = (_servings - 1).clamp(1, 50)),
                        icon: const Icon(
                            Icons.remove_circle_outline,
                            color: kTextSecondary),
                      ),
                      Text('$_servings',
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      IconButton(
                        onPressed: () => setState(
                            () => _servings = (_servings + 1).clamp(1, 50)),
                        icon: const Icon(Icons.add_circle_outline,
                            color: kNeonYellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredients (${_ingredients.length})',
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add,
                            color: kNeonYellow, size: 16),
                        label: const Text('Add',
                            style: TextStyle(color: kNeonYellow)),
                      ),
                    ],
                  ),
                  ..._ingredients.asMap().entries.map((e) =>
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value.name,
                            style: const TextStyle(
                                color: kTextPrimary, fontSize: 13)),
                        subtitle: Text(
                            '${e.value.amountG.toStringAsFixed(0)}g · ${e.value.calories.toInt()} kcal',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              color: kTextSecondary, size: 18),
                          onPressed: () => setState(
                              () => _ingredients.removeAt(e.key)),
                        ),
                      )),
                  if (_ingredients.isNotEmpty) ...[
                    const Divider(color: Color(0xFF2A3550)),
                    Text(
                      'Total: ${totalCal.toInt()} kcal · ${(totalCal / _servings).toInt()} kcal/serving',
                      style: const TextStyle(
                          color: kNeonYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _nameCtrl.text.isNotEmpty && _ingredients.isNotEmpty
                              ? _save
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonYellow,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Recipe',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ingredient Search Sheet (USDA) ────────────────────────────────────────────

class _IngredientSearchSheet extends StatefulWidget {
  final void Function(RecipeIngredient) onAdded;
  const _IngredientSearchSheet({required this.onAdded});

  @override
  State<_IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<_IngredientSearchSheet> {
  final _searchCtrl = TextEditingController();
  final _amtCtrl = TextEditingController(text: '100');
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amtCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search'
        '?query=${Uri.encodeComponent(query.trim())}'
        '&pageSize=15'
        '&dataType=Foundation,SR%20Legacy,Branded'
        '&api_key=ksmVttTD7HULBghripcKmMyao7wzpzOd72swy5Kl',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final foods = (data['foods'] as List?) ?? [];
        setState(() {
          _results = foods.map<Map<String, dynamic>>((f) {
            final nutrients = (f['foodNutrients'] as List?) ?? [];
            double getN(int id) =>
                (nutrients.firstWhere((n) => n['nutrientId'] == id,
                        orElse: () => {})['value'] as num?)
                    ?.toDouble() ??
                0;
            return {
              'name': f['description'] as String? ?? '',
              'cal': getN(1008),
              'p': getN(1003),
              'c': getN(1005),
              'f': getN(1004),
            };
          }).where((f) => (f['name'] as String).isNotEmpty).toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pick(Map<String, dynamic> food) {
    setState(() {
      _selected = food;
      _searchCtrl.text = food['name'] as String;
      _results = [];
    });
  }

  void _confirm() {
    final food = _selected;
    if (food == null) return;
    final grams = double.tryParse(_amtCtrl.text) ?? 100;
    final ratio = grams / 100;
    widget.onAdded(RecipeIngredient(
      name: food['name'] as String,
      calories: ((food['cal'] as double) * ratio),
      protein: ((food['p'] as double) * ratio),
      carbs: ((food['c'] as double) * ratio),
      fat: ((food['f'] as double) * ratio),
      amountG: grams,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFF2A3550), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(child: Text('Add Ingredient', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 17))),
                  IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) {
                  _onSearchChanged(v);
                  if (_selected != null) setState(() => _selected = null);
                },
                decoration: InputDecoration(
                  hintText: 'Search food database…',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: _searching
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kNeonYellow)))
                      : const Icon(Icons.search, color: kTextSecondary),
                  filled: true,
                  fillColor: kCardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (_results.isNotEmpty)
                    ..._results.map((food) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      title: Text(food['name'] as String,
                          style: const TextStyle(color: kTextPrimary, fontSize: 13)),
                      subtitle: Text(
                          '${(food['cal'] as double).toInt()} kcal · P ${(food['p'] as double).toInt()}g · C ${(food['c'] as double).toInt()}g · F ${(food['f'] as double).toInt()}g  (per 100g)',
                          style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                      onTap: () => _pick(food),
                    )),
                  if (_selected != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kNeonYellow.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!['name'] as String,
                              style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Text('Amount (g):', style: TextStyle(color: kTextSecondary)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _amtCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: kSurfaceDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Builder(builder: (_) {
                            final g = double.tryParse(_amtCtrl.text) ?? 100;
                            final r = g / 100;
                            final s = _selected!;
                            return Text(
                              '${((s['cal'] as double) * r).toInt()} kcal · '
                              'P ${((s['p'] as double) * r).toStringAsFixed(1)}g · '
                              'C ${((s['c'] as double) * r).toStringAsFixed(1)}g · '
                              'F ${((s['f'] as double) * r).toStringAsFixed(1)}g',
                              style: const TextStyle(color: kNeonYellow, fontSize: 12, fontWeight: FontWeight.bold),
                            );
                          }),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kNeonYellow,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Add to Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Recipe Sheet ─────────────────────────────────────────────────────────

class _EditRecipeSheet extends StatefulWidget {
  final Recipe recipe;
  final WidgetRef ref;
  const _EditRecipeSheet({required this.recipe, required this.ref});

  @override
  State<_EditRecipeSheet> createState() => _EditRecipeSheetState();
}

class _EditRecipeSheetState extends State<_EditRecipeSheet> {
  late TextEditingController _nameCtrl;
  late int _servings;
  late List<RecipeIngredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.recipe.name);
    _servings = widget.recipe.servings;
    _ingredients = List.from(widget.recipe.ingredients);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _editIngredient(int index) {
    final ing = _ingredients[index];
    final nameC = TextEditingController(text: ing.name);
    final calC = TextEditingController(text: ing.calories.toStringAsFixed(0));
    final proC = TextEditingController(text: ing.protein.toStringAsFixed(1));
    final carC = TextEditingController(text: ing.carbs.toStringAsFixed(1));
    final fatC = TextEditingController(text: ing.fat.toStringAsFixed(1));
    final amtC = TextEditingController(text: ing.amountG.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Ingredient', style: TextStyle(color: kTextPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ingField('Name', nameC),
              _ingField('Amount (g)', amtC, type: TextInputType.number),
              _ingField('Calories', calC, type: TextInputType.number),
              _ingField('Protein (g)', proC, type: TextInputType.number),
              _ingField('Carbs (g)', carC, type: TextInputType.number),
              _ingField('Fat (g)', fatC, type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return;
              setState(() {
                _ingredients[index] = RecipeIngredient(
                  name: nameC.text.trim(),
                  calories: double.tryParse(calC.text) ?? 0,
                  protein: double.tryParse(proC.text) ?? 0,
                  carbs: double.tryParse(carC.text) ?? 0,
                  fat: double.tryParse(fatC.text) ?? 0,
                  amountG: double.tryParse(amtC.text) ?? 100,
                );
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow, foregroundColor: Colors.black),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    final nameC = TextEditingController();
    final calC = TextEditingController();
    final proC = TextEditingController();
    final carC = TextEditingController();
    final fatC = TextEditingController();
    final amtC = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Ingredient', style: TextStyle(color: kTextPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ingField('Name', nameC),
              _ingField('Amount (g)', amtC, type: TextInputType.number),
              _ingField('Calories', calC, type: TextInputType.number),
              _ingField('Protein (g)', proC, type: TextInputType.number),
              _ingField('Carbs (g)', carC, type: TextInputType.number),
              _ingField('Fat (g)', fatC, type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return;
              setState(() {
                _ingredients.add(RecipeIngredient(
                  name: nameC.text.trim(),
                  calories: double.tryParse(calC.text) ?? 0,
                  protein: double.tryParse(proC.text) ?? 0,
                  carbs: double.tryParse(carC.text) ?? 0,
                  fat: double.tryParse(fatC.text) ?? 0,
                  amountG: double.tryParse(amtC.text) ?? 100,
                ));
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kNeonYellow, foregroundColor: Colors.black),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _ingField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kTextSecondary),
          filled: true,
          fillColor: kCardDark,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _ingredients.isEmpty) return;
    widget.ref.read(recipeProvider.notifier).saveRecipe(Recipe(
      id: widget.recipe.id,
      name: _nameCtrl.text.trim(),
      servings: _servings,
      ingredients: _ingredients,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalCal = _ingredients.fold(0.0, (s, i) => s + i.calories);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFF2A3550),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Recipe',
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
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Recipe Name',
                      labelStyle: const TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kCardDark,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Servings:', style: TextStyle(color: kTextSecondary)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(
                            () => _servings = (_servings - 1).clamp(1, 50)),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: kTextSecondary),
                      ),
                      Text('$_servings',
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      IconButton(
                        onPressed: () => setState(
                            () => _servings = (_servings + 1).clamp(1, 50)),
                        icon: const Icon(Icons.add_circle_outline,
                            color: kNeonYellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingredients (${_ingredients.length})',
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add, color: kNeonYellow, size: 16),
                        label: const Text('Add', style: TextStyle(color: kNeonYellow)),
                      ),
                    ],
                  ),
                  ..._ingredients.asMap().entries.map((e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value.name,
                            style: const TextStyle(
                                color: kTextPrimary, fontSize: 13)),
                        subtitle: Text(
                            '${e.value.amountG.toStringAsFixed(0)}g · ${e.value.calories.toInt()} kcal',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: kTextSecondary, size: 18),
                              onPressed: () => _editIngredient(e.key),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: kTextSecondary, size: 18),
                              onPressed: () =>
                                  setState(() => _ingredients.removeAt(e.key)),
                            ),
                          ],
                        ),
                      )),
                  if (_ingredients.isNotEmpty) ...[
                    const Divider(color: Color(0xFF2A3550)),
                    Text(
                      'Total: ${totalCal.toInt()} kcal · ${(totalCal / _servings).toInt()} kcal/serving',
                      style: const TextStyle(
                          color: kNeonYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nameCtrl.text.isNotEmpty && _ingredients.isNotEmpty
                          ? _save
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorites Tab ─────────────────────────────────────────────────────────────

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteFoodsProvider);

    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, color: kNeonYellow, size: 48),
            SizedBox(height: 16),
            Text('No favorites yet',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(height: 6),
            Text('Tap the bookmark icon on any food entry\nto save it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, color: kNeonYellow, size: 18),
            const SizedBox(width: 8),
            const Text('Favorites',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const Spacer(),
            Text('${favorites.length} saved',
                style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: favorites
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        if (e.key > 0)
                          const Divider(height: 1, color: Color(0xFF2A3550)),
                        _FavoriteTile(fav: e.value),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final FoodEntry fav;
  const _FavoriteTile({required this.fav});

  void _quickAdd(BuildContext context, WidgetRef ref) {
    MealType selected = MealType.breakfast;
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(fav.name,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                  '${fav.calories.toInt()} kcal · P: ${fav.protein.toInt()}g  C: ${fav.carbs.toInt()}g  F: ${fav.fat.toInt()}g',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              const Text('Add to:',
                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MealType.values.map((m) {
                  final isSelected = selected == m;
                  return GestureDetector(
                    onTap: () => setState(() => selected = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? kNeonYellow : const Color(0xFF2A3550),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.name[0].toUpperCase() + m.name.substring(1),
                        style: TextStyle(
                          color: isSelected ? Colors.black : kTextSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(foodLogProvider.notifier).addEntry(FoodEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: fav.name,
                        calories: fav.calories,
                        protein: fav.protein,
                        carbs: fav.carbs,
                        fat: fav.fat,
                        servingSize: fav.servingSize,
                        servingUnit: fav.servingUnit,
                        meal: selected,
                        loggedAt: DateTime.now(),
                      ));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add to Log',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fav.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                    '${fav.calories.toInt()} kcal · P: ${fav.protein.toInt()}g  C: ${fav.carbs.toInt()}g  F: ${fav.fat.toInt()}g',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _quickAdd(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  Text('Add',
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
            onTap: () => ref.read(favoriteFoodsProvider.notifier).toggle(fav),
            child: const Icon(Icons.bookmark, color: kNeonYellow, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Food Scan Sheet (AI plate scanner) ────────────────────────────────────────

enum _ScanStep { idle, loading, results, error }

class _FoodScanSheet extends ConsumerStatefulWidget {
  const _FoodScanSheet();

  @override
  ConsumerState<_FoodScanSheet> createState() => _FoodScanSheetState();
}

class _FoodScanSheetState extends ConsumerState<_FoodScanSheet> {
  _ScanStep _step = _ScanStep.idle;
  List<Map<String, dynamic>> _detected = [];
  MealType _meal = MealType.lunch;
  String _errorMsg = '';

  Future<void> _scan(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (image == null || !mounted) return;

    setState(() => _step = _ScanStep.loading);
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      const apiKey = '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';
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                },
                {
                  'type': 'text',
                  'text': 'Identify every distinct food item visible in this photo. '
                      'For each item, estimate the macros for the visible portion. '
                      'Respond ONLY with a JSON object — no markdown, no explanation:\n'
                      '{"items":[{"name":"Food Name","calories":300,"protein":25,"carbs":30,"fat":10,"servingSize":1,"servingUnit":"serving"}]}\n'
                      'If no food is visible, return {"items":[]}.',
                },
              ],
            }
          ],
          'temperature': 0.1,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('API ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['choices'][0]['message']['content'] as String;
      String jsonText = text.trim();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(jsonText);
      if (jsonMatch != null) jsonText = jsonMatch.group(0)!;

      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
      final items = (parsed['items'] as List).cast<Map<String, dynamic>>();
      if (items.isEmpty) {
        setState(() {
          _errorMsg = 'No food detected. Try a clearer or closer shot.';
          _step = _ScanStep.error;
        });
      } else {
        setState(() {
          _detected = items;
          _step = _ScanStep.results;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Scan failed: $e';
        _step = _ScanStep.error;
      });
    }
  }

  void _logAll() {
    final now = DateTime.now();
    for (var i = 0; i < _detected.length; i++) {
      final food = _detected[i];
      ref.read(foodLogProvider.notifier).addEntry(FoodEntry(
            id: '${now.millisecondsSinceEpoch}_scan_$i',
            name: food['name'] as String,
            calories: (food['calories'] as num).toDouble(),
            protein: (food['protein'] as num).toDouble(),
            carbs: (food['carbs'] as num).toDouble(),
            fat: (food['fat'] as num).toDouble(),
            servingSize: (food['servingSize'] as num?)?.toDouble() ?? 1,
            servingUnit: (food['servingUnit'] as String?) ?? 'serving',
            meal: _meal,
            loggedAt: now,
          ));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kCardDark,
        content: Text(
          '${_detected.length} item(s) logged to ${_meal.name}!',
          style: const TextStyle(color: kTextPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
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
                const Icon(Icons.camera_alt_outlined,
                    color: kNeonYellow, size: 22),
                const SizedBox(width: 10),
                const Text('Scan Your Plate',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                if (_step == _ScanStep.idle) _buildIdle(),
                if (_step == _ScanStep.loading) _buildLoading(),
                if (_step == _ScanStep.error) _buildError(),
                if (_step == _ScanStep.results) _buildResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() => Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Take a photo or pick one from your gallery.\nAI will identify the food and estimate macros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _ScanSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _scan(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScanSourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _scan(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            CircularProgressIndicator(color: kNeonYellow, strokeWidth: 2.5),
            SizedBox(height: 20),
            Text('Analysing your plate...',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ],
        ),
      );

  Widget _buildError() => Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(_errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _step = _ScanStep.idle),
            child: const Text('Try Again',
                style: TextStyle(
                    color: kNeonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      );

  Widget _buildResults() {
    final totalCal =
        _detected.fold(0.0, (s, f) => s + (f['calories'] as num));
    final totalProt =
        _detected.fold(0.0, (s, f) => s + (f['protein'] as num));
    final totalCarbs =
        _detected.fold(0.0, (s, f) => s + (f['carbs'] as num));
    final totalFat = _detected.fold(0.0, (s, f) => s + (f['fat'] as num));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroStat('${totalCal.toInt()}', 'kcal', kNeonYellow),
              _MacroStat(
                  '${totalProt.toInt()}g', 'Protein', Colors.greenAccent),
              _MacroStat('${totalCarbs.toInt()}g', 'Carbs',
                  const Color(0xFF60A5FA)),
              _MacroStat('${totalFat.toInt()}g', 'Fat',
                  const Color(0xFFFBBF24)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('${_detected.length} item(s) detected',
            style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ..._detected.map((food) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food['name'] as String,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          'P: ${(food['protein'] as num).toInt()}g  C: ${(food['carbs'] as num).toInt()}g  F: ${(food['fat'] as num).toInt()}g',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(food['calories'] as num).toInt()} kcal',
                    style: const TextStyle(
                        color: kNeonYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        const Text('Log to:',
            style: TextStyle(color: kTextSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MealType.values.map((m) {
            final selected = m == _meal;
            return GestureDetector(
              onTap: () => setState(() => _meal = m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? kNeonYellow : const Color(0xFF2A3550),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  m.name[0].toUpperCase() + m.name.substring(1),
                  style: TextStyle(
                    color: selected ? Colors.black : kTextSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _ScanStep.idle),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2A3550)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Re-scan',
                    style: TextStyle(color: kTextSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _logAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Log All',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ScanSourceButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kNeonYellow.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kNeonYellow, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MacroStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style:
                const TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}
