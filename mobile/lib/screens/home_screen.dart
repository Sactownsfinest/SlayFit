import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'food_log_screen.dart';
import 'progress_screen.dart';
import 'activity_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    FoodLogScreen(),
    ActivityScreen(),
    ProgressScreen(),
    _ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurfaceDark,
          border: Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.restaurant_outlined,
                  activeIcon: Icons.restaurant,
                  label: 'Food',
                  index: 1,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center,
                  label: 'Activity',
                  index: 2,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.trending_down_outlined,
                  activeIcon: Icons.trending_down,
                  label: 'Progress',
                  index: 3,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kNeonYellow : kTextSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kNeonYellow : kTextSecondary,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Profile'),
        ),
        SliverFillRemaining(
          child: Center(
            child: Text('Profile coming in Phase 3',
                style: TextStyle(color: kTextSecondary)),
          ),
        ),
      ],
    );
  }
}
