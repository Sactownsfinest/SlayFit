import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import '../providers/health_provider.dart';

String _fmtWeight(double kg, bool metric) =>
    metric ? '${kg.toStringAsFixed(1)} kg' : '${(kg * 2.20462).toStringAsFixed(1)} lbs';

String _fmtHeight(double cm, bool metric) {
  if (metric) return '${cm.toStringAsFixed(0)} cm';
  final totalIn = (cm / 2.54).round();
  return "${totalIn ~/ 12}' ${totalIn % 12}\"";
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final weight = ref.watch(weightProvider);
    final streak = ref.watch(streakProvider);
    final water = ref.watch(waterProvider);
    final health = ref.watch(healthProvider);

    final initials = profile.name.trim().isNotEmpty
        ? profile.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Profile'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Avatar
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _editProfile(context, ref, profile),
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: kNeonYellow,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: kSurfaceDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: kNeonYellow, width: 1.5),
                              ),
                              child: const Icon(Icons.edit, size: 12, color: kNeonYellow),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _editProfile(context, ref, profile),
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: const TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Current',
                      value: weight.latest != null
                          ? _fmtWeight(weight.latest!.weightKg, profile.useMetric)
                          : '—',
                      color: kNeonYellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Goal',
                      value: _fmtWeight(profile.goalWeightKg, profile.useMetric),
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Calories',
                      value: '${profile.dailyCalorieGoal}',
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goals section
              _SectionHeader('GOALS'),
              const SizedBox(height: 8),
              _SettingsCard(children: [
                _SettingsRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Daily Calories',
                  value: '${profile.dailyCalorieGoal} kcal',
                  onTap: () => _editCalories(context, ref, profile),
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.flag_outlined,
                  label: 'Target Weight',
                  value: _fmtWeight(profile.goalWeightKg, profile.useMetric),
                  onTap: () => _editGoalWeight(context, ref, profile),
                ),
              ]),
              const SizedBox(height: 20),

              // Body section
              _SectionHeader('BODY'),
              const SizedBox(height: 8),
              _SettingsCard(children: [
                _SettingsRow(
                  icon: Icons.swap_horiz_outlined,
                  label: 'Units',
                  value: profile.useMetric ? 'kg / cm' : 'lbs / ft·in',
                  onTap: () => ref.read(userProfileProvider.notifier).update(
                        profile.copyWith(useMetric: !profile.useMetric),
                      ),
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Current Weight',
                  value: weight.latest != null
                      ? _fmtWeight(weight.latest!.weightKg, profile.useMetric)
                      : 'Not set',
                  onTap: () => _editCurrentWeight(context, ref, profile, weight),
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.straighten_outlined,
                  label: 'Height',
                  value: _fmtHeight(profile.heightCm, profile.useMetric),
                  onTap: () => _editHeight(context, ref, profile),
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.wc_outlined,
                  label: 'Sex',
                  value: profile.sex == 'M'
                      ? 'Male'
                      : profile.sex == 'F'
                          ? 'Female'
                          : 'Other',
                  onTap: () => _editSex(context, ref, profile),
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.directions_run_outlined,
                  label: 'Activity Level',
                  value: profile.activityLevelLabel,
                  onTap: () => _editActivity(context, ref, profile),
                ),
              ]),
              const SizedBox(height: 20),

              // Macro breakdown
              _SectionHeader('DAILY MACROS'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroChip(
                        label: 'Protein',
                        value: '${profile.proteinGoalG}g',
                        color: const Color(0xFF60A5FA)),
                    _MacroChip(
                        label: 'Carbs',
                        value: '${profile.carbsGoalG}g',
                        color: const Color(0xFFFBBF24)),
                    _MacroChip(
                        label: 'Fat',
                        value: '${profile.fatGoalG}g',
                        color: const Color(0xFFF87171)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Streak summary
              _SectionHeader('STREAK'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroChip(
                      label: 'Current',
                      value: '${streak.currentStreak}🔥',
                      color: Colors.orangeAccent,
                    ),
                    _MacroChip(
                      label: 'Longest',
                      value: '${streak.longestStreak}',
                      color: kNeonYellow,
                    ),
                    _MacroChip(
                      label: 'Water Goal',
                      value: '${water.dailyGoalMl}ml',
                      color: const Color(0xFF60A5FA),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Achievements
              _SectionHeader('ACHIEVEMENTS'),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: streak.achievements.map((a) {
                  return _AchievementBadge(achievement: a);
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Health Connect
              _SectionHeader('HEALTH CONNECT'),
              const SizedBox(height: 8),
              _HealthConnectCard(health: health),
              const SizedBox(height: 20),

              // Reminders
              _SectionHeader('REMINDERS'),
              const SizedBox(height: 8),
              _RemindersCard(),
              const SizedBox(height: 20),

              // Water goal
              _SectionHeader('WATER GOAL'),
              const SizedBox(height: 8),
              _SettingsCard(children: [
                _SettingsRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Daily Water Goal',
                  value: '${(water.dailyGoalMl / 29.5735).round()} oz',
                  onTap: () => _editWaterGoal(context, ref, water.dailyGoalMl),
                ),
              ]),
              const SizedBox(height: 28),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref, UserProfile profile) {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline, color: kTextSecondary),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: kTextPrimary),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: kTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (name.isNotEmpty) {
                final updated = profile.copyWith(name: name, email: email);
                ref.read(userProfileProvider.notifier).update(updated);
                // Keep legacy separate keys in sync
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', name);
                await prefs.setString('user_email', email);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editCurrentWeight(
      BuildContext context, WidgetRef ref, UserProfile profile, WeightState weight) {
    final metric = profile.useMetric;
    final current = weight.latest?.weightKg;
    final displayVal = current != null
        ? (metric ? current.toStringAsFixed(1) : (current * 2.20462).toStringAsFixed(1))
        : '';
    final controller = TextEditingController(text: displayVal);
    _showEditDialog(
      context: context,
      title: 'Current Weight',
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: kTextPrimary, fontSize: 24),
        textAlign: TextAlign.center,
        decoration: InputDecoration(suffixText: metric ? 'kg' : 'lbs'),
        autofocus: true,
      ),
      onSave: () {
        final val = double.tryParse(controller.text);
        if (val != null && val > 0) {
          final kg = metric ? val : val / 2.20462;
          ref.read(weightProvider.notifier).logWeight(kg);
          // Auto water goal: 35 ml per kg body weight
          ref.read(waterProvider.notifier).setGoal((kg * 35).round());
        }
      },
    );
  }

  void _editCalories(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final controller =
        TextEditingController(text: profile.dailyCalorieGoal.toString());
    _showEditDialog(
      context: context,
      title: 'Daily Calorie Goal',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: kTextPrimary, fontSize: 24),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(suffixText: 'kcal'),
        autofocus: true,
      ),
      onSave: () {
        final val = int.tryParse(controller.text);
        if (val != null && val > 0) {
          ref.read(userProfileProvider.notifier).update(
                profile.copyWith(dailyCalorieGoal: val),
              );
          ref.read(foodLogProvider.notifier).setCalorieGoal(val.toDouble());
        }
      },
    );
  }

  void _editGoalWeight(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final metric = profile.useMetric;
    final displayVal = metric
        ? profile.goalWeightKg.toStringAsFixed(1)
        : (profile.goalWeightKg * 2.20462).toStringAsFixed(1);
    final controller = TextEditingController(text: displayVal);
    _showEditDialog(
      context: context,
      title: 'Target Weight',
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: kTextPrimary, fontSize: 24),
        textAlign: TextAlign.center,
        decoration: InputDecoration(suffixText: metric ? 'kg' : 'lbs'),
        autofocus: true,
      ),
      onSave: () {
        final val = double.tryParse(controller.text);
        if (val != null && val > 0) {
          final kg = metric ? val : val / 2.20462;
          ref.read(userProfileProvider.notifier).update(
                profile.copyWith(goalWeightKg: kg),
              );
          ref.read(weightProvider.notifier).setGoal(kg);
        }
      },
    );
  }

  void _editHeight(BuildContext context, WidgetRef ref, UserProfile profile) {
    if (profile.useMetric) {
      final controller =
          TextEditingController(text: profile.heightCm.toStringAsFixed(0));
      _showEditDialog(
        context: context,
        title: 'Height',
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kTextPrimary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(suffixText: 'cm'),
          autofocus: true,
        ),
        onSave: () {
          final val = double.tryParse(controller.text);
          if (val != null && val > 0) {
            ref.read(userProfileProvider.notifier).update(
                  profile.copyWith(heightCm: val),
                );
          }
        },
      );
    } else {
      final totalIn = (profile.heightCm / 2.54).round();
      final feetCtrl =
          TextEditingController(text: (totalIn ~/ 12).toString());
      final inchesCtrl =
          TextEditingController(text: (totalIn % 12).toString());
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurfaceDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Height',
              style: TextStyle(
                  color: kTextPrimary, fontWeight: FontWeight.bold)),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: feetCtrl,
                  keyboardType: TextInputType.number,
                  style:
                      const TextStyle(color: kTextPrimary, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(suffixText: 'ft'),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: inchesCtrl,
                  keyboardType: TextInputType.number,
                  style:
                      const TextStyle(color: kTextPrimary, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(suffixText: 'in'),
                ),
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
                final ft = int.tryParse(feetCtrl.text) ?? 0;
                final inch = int.tryParse(inchesCtrl.text) ?? 0;
                final cm = (ft * 12 + inch) * 2.54;
                if (cm > 0) {
                  ref.read(userProfileProvider.notifier).update(
                        profile.copyWith(heightCm: cm),
                      );
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

  void _editSex(BuildContext context, WidgetRef ref, UserProfile profile) {
    String selected = profile.sex;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: kSurfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sex',
              style: TextStyle(
                  color: kTextPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['M', 'F', 'O'].map((s) {
              final label =
                  s == 'M' ? 'Male' : s == 'F' ? 'Female' : 'Other';
              return RadioListTile<String>(
                value: s,
                groupValue: selected,
                title: Text(label,
                    style: const TextStyle(color: kTextPrimary)),
                activeColor: kNeonYellow,
                onChanged: (v) => setState(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(userProfileProvider.notifier).update(
                      profile.copyWith(sex: selected),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editActivity(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    String selected = profile.activityLevel;
    const levels = {
      'sedentary': 'Sedentary',
      'lightly_active': 'Lightly Active',
      'moderate': 'Moderately Active',
      'very_active': 'Very Active',
    };
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: kSurfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Activity Level',
              style: TextStyle(
                  color: kTextPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: levels.entries.map((e) {
              return RadioListTile<String>(
                value: e.key,
                groupValue: selected,
                title: Text(e.value,
                    style: const TextStyle(color: kTextPrimary)),
                activeColor: kNeonYellow,
                onChanged: (v) => setState(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(userProfileProvider.notifier).update(
                      profile.copyWith(activityLevel: selected),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required Widget child,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: kTextPrimary, fontWeight: FontWeight.bold)),
        content: child,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              onSave();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editWaterGoal(BuildContext context, WidgetRef ref, int currentGoal) {
    final ozVal = (currentGoal / 29.5735).round();
    final controller = TextEditingController(text: ozVal.toString());
    _showEditDialog(
      context: context,
      title: 'Daily Water Goal',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: kTextPrimary, fontSize: 24),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(suffixText: 'oz'),
        autofocus: true,
      ),
      onSave: () {
        final val = int.tryParse(controller.text);
        if (val != null && val > 0) {
          ref.read(waterProvider.notifier).setGoal((val * 29.5735).round());
        }
      },
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style:
                TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                fontSize: 14,
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: kTextSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14)),
            ),
            Text(value,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: kTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 50, color: Color(0xFF2A3550));
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip(
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
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? kNeonYellow.withValues(alpha: 0.12)
            : kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? kNeonYellow.withValues(alpha: 0.4)
              : const Color(0xFF2A3550),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: unlocked ? kNeonYellow : const Color(0xFF2A3550),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              color: unlocked ? kTextPrimary : kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          if (unlocked && achievement.unlockedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day}',
                style: const TextStyle(color: kTextSecondary, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthConnectCard extends ConsumerWidget {
  final HealthState health;
  const _HealthConnectCard({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = health.permissionsGranted;
    return _SettingsCard(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: connected
                        ? const Color(0xFF34D399).withValues(alpha: 0.15)
                        : const Color(0xFF2A3550),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    connected ? Icons.check_circle_outline : Icons.link_outlined,
                    color: connected ? const Color(0xFF34D399) : kTextSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          color: connected ? const Color(0xFF34D399) : kTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        connected
                            ? 'Syncing steps & weight from Health Connect'
                            : 'Sync Fitbit, Garmin, smart scales & more',
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (connected && health.todaySteps != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Today: ${health.todaySteps} steps'
                  '${health.latestWeightKg != null ? '  •  Scale: ${health.latestWeightKg!.toStringAsFixed(1)} kg' : ''}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ),
            Row(
              children: [
                if (!connected)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: health.isLoading
                          ? null
                          : () => ref.read(healthProvider.notifier).requestPermissions(),
                      icon: health.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.link, size: 16),
                      label: const Text('Connect Health Data'),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(healthProvider.notifier).fetchData(),
                      icon: const Icon(Icons.refresh, size: 16, color: kNeonYellow),
                      label: const Text('Refresh', style: TextStyle(color: kNeonYellow)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A3550)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => ref.read(healthProvider.notifier).disconnect(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Disconnect',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ]);
  }
}

class _RemindersCard extends ConsumerStatefulWidget {
  const _RemindersCard();

  @override
  ConsumerState<_RemindersCard> createState() => _RemindersCardState();
}

class _RemindersCardState extends ConsumerState<_RemindersCard> {
  bool _lunchEnabled = false;
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 0);
  bool _eveningEnabled = false;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lunchEnabled = prefs.getBool('lunch_reminder_enabled') ?? false;
      _lunchTime = TimeOfDay(
        hour: prefs.getInt('lunch_reminder_hour') ?? 12,
        minute: prefs.getInt('lunch_reminder_minute') ?? 0,
      );
      _eveningEnabled = prefs.getBool('evening_reminder_enabled') ?? false;
      _eveningTime = TimeOfDay(
        hour: prefs.getInt('evening_reminder_hour') ?? 20,
        minute: prefs.getInt('evening_reminder_minute') ?? 0,
      );
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lunch_reminder_enabled', _lunchEnabled);
    await prefs.setInt('lunch_reminder_hour', _lunchTime.hour);
    await prefs.setInt('lunch_reminder_minute', _lunchTime.minute);
    await prefs.setBool('evening_reminder_enabled', _eveningEnabled);
    await prefs.setInt('evening_reminder_hour', _eveningTime.hour);
    await prefs.setInt('evening_reminder_minute', _eveningTime.minute);
  }

  Future<void> _toggleLunch(bool val) async {
    setState(() => _lunchEnabled = val);
    await _savePrefs();
    if (val) {
      await NotificationService().scheduleLunchReminder(_lunchTime);
    } else {
      await NotificationService().cancelLunchReminder();
    }
  }

  Future<void> _toggleEvening(bool val) async {
    setState(() => _eveningEnabled = val);
    await _savePrefs();
    if (val) {
      await NotificationService().scheduleEveningReminder(_eveningTime);
    } else {
      await NotificationService().cancelEveningReminder();
    }
  }

  Future<void> _pickTime(bool isLunch) async {
    final initial = isLunch ? _lunchTime : _eveningTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isLunch) {
        _lunchTime = picked;
      } else {
        _eveningTime = picked;
      }
    });
    await _savePrefs();
    if (isLunch && _lunchEnabled) {
      await NotificationService().scheduleLunchReminder(picked);
    } else if (!isLunch && _eveningEnabled) {
      await NotificationService().scheduleEveningReminder(picked);
    }
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.lunch_dining_outlined,
                color: kTextSecondary, size: 20),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Lunch Reminder',
                  style: TextStyle(color: kTextPrimary, fontSize: 14)),
            ),
            if (_lunchEnabled)
              GestureDetector(
                onTap: () => _pickTime(true),
                child: Text(_fmt(_lunchTime),
                    style: const TextStyle(
                        color: kNeonYellow, fontSize: 13)),
              ),
            const SizedBox(width: 8),
            Switch(
              value: _lunchEnabled,
              onChanged: _toggleLunch,
              activeThumbColor: kNeonYellow,
            ),
          ],
        ),
      ),
      const Divider(height: 1, indent: 50, color: Color(0xFF2A3550)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.nights_stay_outlined,
                color: kTextSecondary, size: 20),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Evening Reminder',
                  style: TextStyle(color: kTextPrimary, fontSize: 14)),
            ),
            if (_eveningEnabled)
              GestureDetector(
                onTap: () => _pickTime(false),
                child: Text(_fmt(_eveningTime),
                    style: const TextStyle(
                        color: kNeonYellow, fontSize: 13)),
              ),
            const SizedBox(width: 8),
            Switch(
              value: _eveningEnabled,
              onChanged: _toggleEvening,
              activeThumbColor: kNeonYellow,
            ),
          ],
        ),
      ),
    ]);
  }
}
