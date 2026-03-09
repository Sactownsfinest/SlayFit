import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/food_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import '../providers/health_provider.dart';
import '../providers/measurements_provider.dart';
import '../providers/challenges_provider.dart';
import '../services/firebase_service.dart';

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader('ACHIEVEMENTS'),
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: kCardDark,
                          title: const Text('Reset Daily Challenges',
                              style: TextStyle(color: kTextPrimary, fontSize: 16)),
                          content: const Text(
                              'This will clear your active and completed challenges so you can start fresh. Your badges and streak are not affected.',
                              style: TextStyle(color: kTextSecondary, fontSize: 14)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: kTextSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(challengesProvider.notifier).resetAll();
                      }
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
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

              // Measurements
              _SectionHeader('MEASUREMENTS'),
              const SizedBox(height: 8),
              _MeasurementsSummaryCard(),
              const SizedBox(height: 20),

              // Community
              _SectionHeader('COMMUNITY'),
              const SizedBox(height: 8),
              const _CommunityCard(),
              const SizedBox(height: 20),

              // Fitbit
              _SectionHeader('FITBIT'),
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
              const SizedBox(height: 20),

              // Invite Friends
              const _SectionHeader('INVITE'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Share.share(
                    'Hey! Join me on SlayFit — the fitness app I\'ve been using to crush my goals! 💪⚡\n\n'
                    'Download it here: https://github.com/Sactownsfinest/SlayFit/releases/tag/Slayfit',
                  ),
                  icon: const Icon(Icons.person_add_outlined, color: Colors.black),
                  label: const Text('Invite Friends', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeonYellow,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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

class _MeasurementsSummaryCard extends ConsumerStatefulWidget {
  const _MeasurementsSummaryCard();

  @override
  ConsumerState<_MeasurementsSummaryCard> createState() => _MeasurementsSummaryCardState();
}

class _MeasurementsSummaryCardState extends ConsumerState<_MeasurementsSummaryCard> {
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _armsCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();

  @override
  void dispose() {
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _chestCtrl.dispose();
    _armsCtrl.dispose();
    _bodyFatCtrl.dispose();
    super.dispose();
  }

  double? _inToCm(String text) {
    final v = double.tryParse(text.trim());
    return v != null ? v * 2.54 : null;
  }

  void _showAddDialog() {
    _waistCtrl.clear();
    _hipsCtrl.clear();
    _chestCtrl.clear();
    _armsCtrl.clear();
    _bodyFatCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Log Measurements', style: TextStyle(color: kTextPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MeasureField(label: 'Waist (inches)', ctrl: _waistCtrl),
              _MeasureField(label: 'Hips (inches)', ctrl: _hipsCtrl),
              _MeasureField(label: 'Chest (inches)', ctrl: _chestCtrl),
              _MeasureField(label: 'Arms (inches)', ctrl: _armsCtrl),
              _MeasureField(label: 'Body Fat (%)', ctrl: _bodyFatCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () {
              final m = BodyMeasurement(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                date: DateTime.now(),
                waistCm: _inToCm(_waistCtrl.text),
                hipsCm: _inToCm(_hipsCtrl.text),
                chestCm: _inToCm(_chestCtrl.text),
                armsCm: _inToCm(_armsCtrl.text),
                bodyFatPercent: double.tryParse(_bodyFatCtrl.text),
              );
              ref.read(measurementsProvider.notifier).addMeasurement(m);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: kNeonYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(measurementsProvider);
    final latest = measurements.latest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (latest == null)
            Center(
              child: Column(
                children: [
                  const Text('No measurements logged yet', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Measurements'),
                    style: ElevatedButton.styleFrom(backgroundColor: kNeonYellow, foregroundColor: Colors.black),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last logged ${latest.date.month}/${latest.date.day}/${latest.date.year}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: const Text('+ Add', style: TextStyle(color: kNeonYellow, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (latest.waistCm != null) _measureTile('Waist', '${(latest.waistCm! / 2.54).toStringAsFixed(1)} in'),
                if (latest.hipsCm != null) _measureTile('Hips', '${(latest.hipsCm! / 2.54).toStringAsFixed(1)} in'),
                if (latest.chestCm != null) _measureTile('Chest', '${(latest.chestCm! / 2.54).toStringAsFixed(1)} in'),
                if (latest.armsCm != null) _measureTile('Arms', '${(latest.armsCm! / 2.54).toStringAsFixed(1)} in'),
                if (latest.bodyFatPercent != null) _measureTile('Body Fat', '${latest.bodyFatPercent!.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Widget _measureTile(String label, String value) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
    Text(value, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
  ],
);

class _MeasureField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _MeasureField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: kTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kTextSecondary),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2A3550))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kNeonYellow)),
        ),
      ),
    );
  }
}

// ── Community Display Name Card ───────────────────────────────────────────────

class _CommunityCard extends ConsumerStatefulWidget {
  const _CommunityCard();
  @override
  ConsumerState<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends ConsumerState<_CommunityCard> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await FirebaseService.getDisplayName();
    if (mounted) setState(() => _displayName = name);
  }

  void _editName(BuildContext context) {
    final ctrl = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Community Display Name',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your display name',
            hintStyle: TextStyle(color: kTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await FirebaseService.setDisplayName(name);
                if (mounted) setState(() => _displayName = name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(children: [
      _SettingsRow(
        icon: Icons.badge_outlined,
        label: 'Display Name',
        value: _displayName.isEmpty ? 'Not set' : _displayName,
        onTap: () => _editName(context),
      ),
    ]);
  }
}

class _HealthConnectCard extends ConsumerWidget {
  final HealthState health;
  const _HealthConnectCard({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<HealthState>(healthProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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
                            ? 'Syncing steps & weight from Fitbit'
                            : 'Connect your Fitbit for real-time steps & weight',
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
                      label: const Text('Connect Fitbit'),
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
  bool _waterEnabled = false;
  bool _moveEnabled = false;
  bool _missedLogEnabled = false;
  TimeOfDay _missedLogTime = const TimeOfDay(hour: 21, minute: 0);

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
      _waterEnabled = prefs.getBool('water_reminder_enabled') ?? false;
      _moveEnabled = prefs.getBool('move_reminder_enabled') ?? false;
      _missedLogEnabled =
          prefs.getBool('missed_log_reminder_enabled') ?? false;
      _missedLogTime = TimeOfDay(
        hour: prefs.getInt('missed_log_reminder_hour') ?? 21,
        minute: prefs.getInt('missed_log_reminder_minute') ?? 0,
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
    await prefs.setBool('missed_log_reminder_enabled', _missedLogEnabled);
    await prefs.setInt('missed_log_reminder_hour', _missedLogTime.hour);
    await prefs.setInt('missed_log_reminder_minute', _missedLogTime.minute);
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

  Future<void> _toggleWater(bool val) async {
    setState(() => _waterEnabled = val);
    if (val) {
      await NotificationService().scheduleWaterReminders();
    } else {
      await NotificationService().cancelWaterReminders();
    }
  }

  Future<void> _toggleMove(bool val) async {
    setState(() => _moveEnabled = val);
    if (val) {
      await NotificationService().scheduleMoveReminders();
    } else {
      await NotificationService().cancelMoveReminders();
    }
  }

  Future<void> _toggleMissedLog(bool val) async {
    setState(() => _missedLogEnabled = val);
    await _savePrefs();
    if (val) {
      await NotificationService().scheduleMissedLogReminder(_missedLogTime);
    } else {
      await NotificationService().cancelMissedLogReminder();
    }
  }

  Future<void> _pickMissedLogTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _missedLogTime);
    if (picked == null) return;
    setState(() => _missedLogTime = picked);
    await _savePrefs();
    if (_missedLogEnabled) {
      await NotificationService().scheduleMissedLogReminder(picked);
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
      const Divider(height: 1, indent: 50, color: Color(0xFF2A3550)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.water_drop_outlined,
                color: Color(0xFF60A5FA), size: 20),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hourly Water Reminders',
                      style: TextStyle(color: kTextPrimary, fontSize: 14)),
                  Text('Every hour, 9 AM – 5 PM',
                      style: TextStyle(color: kTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: _waterEnabled,
              onChanged: _toggleWater,
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
            const Icon(Icons.directions_walk,
                color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hourly Move Reminders',
                      style: TextStyle(color: kTextPrimary, fontSize: 14)),
                  Text('Encouraging nudge every hour, 9:30 AM – 5:30 PM',
                      style: TextStyle(color: kTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: _moveEnabled,
              onChanged: _toggleMove,
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
            const Icon(Icons.no_meals_outlined,
                color: Color(0xFFF87171), size: 20),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Missed Log Reminder',
                      style: TextStyle(color: kTextPrimary, fontSize: 14)),
                  Text("Don't break your streak!",
                      style: TextStyle(color: kTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (_missedLogEnabled)
              GestureDetector(
                onTap: _pickMissedLogTime,
                child: Text(_fmt(_missedLogTime),
                    style:
                        const TextStyle(color: kNeonYellow, fontSize: 13)),
              ),
            const SizedBox(width: 8),
            Switch(
              value: _missedLogEnabled,
              onChanged: _toggleMissedLog,
              activeThumbColor: kNeonYellow,
            ),
          ],
        ),
      ),
    ]);
  }
}

