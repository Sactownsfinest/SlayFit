import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'food_log_screen.dart';
import 'progress_screen.dart';
import 'activity_screen.dart';
import 'ai_coach_screen.dart';
import 'community_screen.dart';
import '../main.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UpdateInfo? _pendingUpdate;
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getString('skipped_update_version') ?? '';
    if (skipped == info.version) return; // user already dismissed this version
    setState(() => _pendingUpdate = info);
  }

  Future<void> _dismissUpdate(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skipped_update_version', version);
    if (mounted) setState(() => _pendingUpdate = null);
  }

  Future<void> _startUpdate() async {
    if (_pendingUpdate == null) return;
    setState(() { _downloadingUpdate = true; _downloadProgress = 0; });
    final version = _pendingUpdate!.version;
    await UpdateService.downloadAndInstall(
      _pendingUpdate!.downloadUrl,
      onProgress: (p) { if (mounted) setState(() => _downloadProgress = p); },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skipped_update_version', version);
    if (mounted) setState(() { _downloadingUpdate = false; _pendingUpdate = null; });
  }

  static const _screens = [
    DashboardScreen(),
    FoodLogScreen(),
    ActivityScreen(),
    ProgressScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  void _openCoach() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AiCoachScreen(wakeUp: true),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_pendingUpdate != null)
            _UpdateBanner(
              version: _pendingUpdate!.version,
              downloading: _downloadingUpdate,
              progress: _downloadProgress,
              onTap: _startUpdate,
              onDismiss: () => _dismissUpdate(_pendingUpdate!.version),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 4 ? null : _GlowingCoachFab(onTap: _openCoach),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurfaceDark,
          border: Border(top: BorderSide(color: Color(0xFF2A3550), width: 1)),
        ),
        padding: EdgeInsets.fromLTRB(0, 8, 0, MediaQuery.of(context).viewPadding.bottom + 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
            _NavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: 'Food', index: 1, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
            _NavItem(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Activity', index: 2, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
            _NavItem(icon: Icons.trending_down_outlined, activeIcon: Icons.trending_down, label: 'Progress', index: 3, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
            _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Community', index: 4, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 5, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
          ],
        ),
      ),
    );
  }
}

class _GlowingCoachFab extends StatefulWidget {
  final VoidCallback onTap;
  const _GlowingCoachFab({required this.onTap});

  @override
  State<_GlowingCoachFab> createState() => _GlowingCoachFabState();
}

class _GlowingCoachFabState extends State<_GlowingCoachFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kNeonYellow,
            boxShadow: [
              BoxShadow(
                color: kNeonYellow.withValues(alpha: 0.55 * _pulse.value),
                blurRadius: 18 + 12 * _pulse.value,
                spreadRadius: 2 + 4 * _pulse.value,
              ),
              BoxShadow(
                color: kNeonYellow.withValues(alpha: 0.25 * _pulse.value),
                blurRadius: 36 + 20 * _pulse.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
        child: const Icon(Icons.bolt, color: Colors.black, size: 34),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final String version;
  final bool downloading;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _UpdateBanner({
    required this.version,
    required this.downloading,
    required this.progress,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: kNeonYellow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: downloading
            ? Row(children: [
                const Icon(Icons.download, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Downloading update… ${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ],
                  ),
                ),
              ])
            : Row(children: [
                const Icon(Icons.system_update, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Update available — v$version',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Install',
                        style: TextStyle(color: kNeonYellow, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Colors.black, size: 18),
                ),
              ]),
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
        width: 60,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? kNeonYellow : kTextSecondary,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
