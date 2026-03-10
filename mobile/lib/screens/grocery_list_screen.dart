import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../services/claude_service.dart';
import '../main.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _GroceryItem {
  final String name;
  final String qty;
  final String category;
  bool checked = false;

  _GroceryItem({required this.name, required this.qty, required this.category});
}

class _MealEntry {
  final String mealType;
  final String description;
  bool checked;
  _MealEntry({required this.mealType, required this.description, this.checked = false});
}

class _MealDay {
  final int day;
  final List<_MealEntry> meals;
  _MealDay({required this.day, required this.meals});
}

const _categoryOrder = [
  'Produce',
  'Protein',
  'Dairy',
  'Grains',
  'Pantry',
  'Other',
];

const _categoryIcons = {
  'Produce': Icons.eco_outlined,
  'Protein': Icons.set_meal_outlined,
  'Dairy': Icons.local_drink_outlined,
  'Grains': Icons.grain,
  'Pantry': Icons.kitchen_outlined,
  'Other': Icons.shopping_basket_outlined,
};

// ── Screen ────────────────────────────────────────────────────────────────────

class GroceryListScreen extends ConsumerStatefulWidget {
  const GroceryListScreen({super.key});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  bool _loading = false;
  String? _error;
  List<_GroceryItem> _items = [];
  List<_MealDay> _parsedDays = [];
  String _rawMealPlan = '';

  static const _keyRawPlan = 'grocery_raw_plan_v1';
  static const _keyItems = 'grocery_items_v1';
  static const _keyMealChecked = 'grocery_meal_checked_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRawPlan) ?? '';
    final itemsJson = prefs.getString(_keyItems) ?? '';
    if (raw.isEmpty || itemsJson.isEmpty) return;

    final days = _parseMealPlan(raw);
    final checkedJson = prefs.getString(_keyMealChecked) ?? '';
    if (checkedJson.isNotEmpty) {
      final matrix = jsonDecode(checkedJson) as List;
      for (int i = 0; i < matrix.length && i < days.length; i++) {
        final row = matrix[i] as List;
        for (int j = 0; j < row.length && j < days[i].meals.length; j++) {
          days[i].meals[j].checked = row[j] as bool? ?? false;
        }
      }
    }

    final rawList = jsonDecode(itemsJson) as List;
    final items = rawList.map((e) {
      final m = e as Map<String, dynamic>;
      return _GroceryItem(
        name: m['name'] as String,
        qty: m['qty'] as String,
        category: m['category'] as String,
      )..checked = m['checked'] as bool? ?? false;
    }).toList();

    if (mounted) {
      setState(() {
        _rawMealPlan = raw;
        _parsedDays = days;
        _items = items;
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRawPlan, _rawMealPlan);
    await prefs.setString(
      _keyItems,
      jsonEncode(_items.map((i) => {'name': i.name, 'qty': i.qty, 'category': i.category, 'checked': i.checked}).toList()),
    );
    await prefs.setString(
      _keyMealChecked,
      jsonEncode(_parsedDays.map((d) => d.meals.map((m) => m.checked).toList()).toList()),
    );
  }

  Color _mealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return const Color(0xFFFF9500);
      case 'lunch':     return const Color(0xFF34C759);
      case 'dinner':    return const Color(0xFF007AFF);
      default:          return const Color(0xFFBF5AF2); // snack
    }
  }

  List<_MealDay> _parseMealPlan(String raw) {
    final days = <_MealDay>[];
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    _MealDay? current;
    final dayRx = RegExp(r'^Day\s+(\d+)', caseSensitive: false);
    final mealRx = RegExp(r'^(Breakfast|Lunch|Dinner|Snack)[:\s]+(.+)', caseSensitive: false);
    for (final line in lines) {
      final d = dayRx.firstMatch(line);
      if (d != null) {
        if (current != null) days.add(current);
        current = _MealDay(day: int.tryParse(d.group(1) ?? '1') ?? 1, meals: []);
        continue;
      }
      final m = mealRx.firstMatch(line);
      if (m != null && current != null) {
        current.meals.add(_MealEntry(mealType: m.group(1)!, description: m.group(2)!.trim()));
      }
    }
    if (current != null) days.add(current);
    return days;
  }

  Map<String, List<_GroceryItem>> get _grouped {
    final m = <String, List<_GroceryItem>>{};
    for (final item in _items) {
      final cat = _categoryOrder.contains(item.category) ? item.category : 'Other';
      m.putIfAbsent(cat, () => []).add(item);
    }
    return m;
  }

  Future<void> _generate() async {
    final profile = ref.read(userProfileProvider);

    final calorieGoal = profile.dailyCalorieGoal;
    final proteinGoal = profile.proteinGoalG;
    final carbGoal = profile.carbsGoalG;
    final fatGoal = profile.fatGoalG;
    final name = profile.name.split(' ').first;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ClaudeService.generateGroceryList(
        calorieGoal: calorieGoal,
        proteinG: proteinGoal,
        carbsG: carbGoal,
        fatG: fatGoal,
        name: name,
      );

      final mealPlan = result['mealPlan'] as String? ?? '';
      final rawList = result['groceries'] as List<dynamic>? ?? [];

      final items = rawList.map((e) {
        final m = e as Map<String, dynamic>;
        return _GroceryItem(
          name: m['item'] as String? ?? '',
          qty: m['qty'] as String? ?? '',
          category: m['category'] as String? ?? 'Other',
        );
      }).where((i) => i.name.isNotEmpty).toList();

      setState(() {
        _rawMealPlan = mealPlan;
        _parsedDays = _parseMealPlan(mealPlan);
        _items = items;
        _loading = false;
      });
      _persist();
    } catch (e) {
      setState(() {
        _error = 'Could not generate list. Please try again.';
        _loading = false;
      });
    }
  }

  String _buildShareText() {
    final buf = StringBuffer('🛒 SlayFit Grocery List\n\n');
    for (final cat in _categoryOrder) {
      final group = _grouped[cat];
      if (group == null || group.isEmpty) continue;
      buf.writeln('── $cat ──');
      for (final item in group) {
        buf.writeln('• ${item.name}${item.qty.isNotEmpty ? "  (${item.qty})" : ""}');
      }
      buf.writeln();
    }
    return buf.toString().trim();
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _buildShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grocery list copied to clipboard'),
        backgroundColor: kCardDark,
      ),
    );
  }

  void _shareAll() => Share.share(_buildShareText(), subject: 'SlayFit Grocery List');

  Future<void> _openInstacart(String itemName) async {
    final encoded = Uri.encodeComponent(itemName);
    final uri = Uri.parse('https://www.instacart.com/store/s?k=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Instacart')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        backgroundColor: kSurfaceDark,
        title: const Text('Grocery List'),
        actions: _items.isEmpty
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.copy_outlined, color: kTextSecondary),
                  tooltip: 'Copy list',
                  onPressed: _copyAll,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: kTextSecondary),
                  tooltip: 'Share list',
                  onPressed: _shareAll,
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: _loading
          ? _buildLoading()
          : _items.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kNeonYellow),
          SizedBox(height: 20),
          Text(
            'Building your grocery list…',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'This takes about 30 seconds',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              child: const Icon(Icons.shopping_cart_outlined,
                  color: kNeonYellow, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Grocery List',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate a personalised 7-day meal plan and get a ready-to-shop grocery list based on your calorie and macro goals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate Grocery List',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Instacart banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00892E).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF00892E).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shopping_basket, color: Color(0xFF00892E), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap  🔍  on any item to search it on Instacart',
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // 7-Day Meal Plan — checkable day cards
        if (_parsedDays.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(Icons.restaurant_menu, color: kNeonYellow, size: 16),
              SizedBox(width: 6),
              Text('7-Day Meal Plan', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
          ..._parsedDays.map((dayPlan) {
            final allChecked = dayPlan.meals.every((m) => m.checked);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allChecked ? kNeonYellow.withValues(alpha: 0.4) : const Color(0xFF2A3550),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  leading: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: allChecked ? kNeonYellow.withValues(alpha: 0.15) : const Color(0xFF1E2D45),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: allChecked
                          ? const Icon(Icons.check, color: kNeonYellow, size: 16)
                          : Text('${dayPlan.day}', style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  title: Text(
                    'Day ${dayPlan.day}',
                    style: TextStyle(
                      color: allChecked ? kNeonYellow : kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: allChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    dayPlan.meals.map((m) => m.mealType).join(' · '),
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                  iconColor: kTextSecondary,
                  collapsedIconColor: kTextSecondary,
                  children: dayPlan.meals.map((meal) {
                    final mealColor = _mealTypeColor(meal.mealType);
                    return CheckboxListTile(
                      value: meal.checked,
                      onChanged: (v) {
                        setState(() => meal.checked = v ?? false);
                        _persist();
                      },
                      activeColor: kNeonYellow,
                      checkColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                      title: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: mealColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(meal.mealType, style: TextStyle(color: mealColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          meal.description,
                          style: TextStyle(
                            color: meal.checked ? kTextSecondary : kTextPrimary,
                            fontSize: 12,
                            decoration: meal.checked ? TextDecoration.lineThrough : null,
                          ),
                        )),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Grocery list by category
        for (final cat in _categoryOrder)
          if (grouped.containsKey(cat)) ...[
            _CategoryHeader(cat),
            ...grouped[cat]!.map((item) => _GroceryTile(
                  item: item,
                  onChanged: (v) => setState(() => item.checked = v ?? false),
                  onInstacart: () => _openInstacart(item.name),
                )),
            const SizedBox(height: 8),
          ],

        // Bottom actions
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _items = [];
                    _parsedDays = [];
                  });
                  _generate();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  side: const BorderSide(color: Color(0xFF2A3550)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareAll,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader(this.category);

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category] ?? Icons.shopping_basket_outlined;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(icon, color: kNeonYellow, size: 15),
          const SizedBox(width: 7),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              color: kNeonYellow,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroceryTile extends StatelessWidget {
  final _GroceryItem item;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onInstacart;
  const _GroceryTile(
      {required this.item,
      required this.onChanged,
      required this.onInstacart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.checked
              ? const Color(0xFF2A3550)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.checked,
            onChanged: onChanged,
            activeColor: kNeonYellow,
            checkColor: Colors.black,
            side: const BorderSide(color: Color(0xFF4A5568)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: item.checked ? kTextSecondary : kTextPrimary,
                    fontSize: 14,
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: kTextSecondary,
                  ),
                ),
                if (item.qty.isNotEmpty)
                  Text(
                    item.qty,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onInstacart,
            icon: const Icon(Icons.search, color: kTextSecondary, size: 20),
            tooltip: 'Find on Instacart',
          ),
        ],
      ),
    );
  }
}
