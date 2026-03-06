import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthState {
  final bool permissionsGranted;
  final int? todaySteps;
  final double? latestWeightKg;
  final bool isLoading;

  const HealthState({
    this.permissionsGranted = false,
    this.todaySteps,
    this.latestWeightKg,
    this.isLoading = false,
  });

  HealthState copyWith({
    bool? permissionsGranted,
    int? todaySteps,
    double? latestWeightKg,
    bool? isLoading,
  }) =>
      HealthState(
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        todaySteps: todaySteps ?? this.todaySteps,
        latestWeightKg: latestWeightKg ?? this.latestWeightKg,
        isLoading: isLoading ?? this.isLoading,
      );
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(const HealthState()) {
    _init();
  }

  static const _types = [HealthDataType.STEPS, HealthDataType.WEIGHT];
  static final _permissions = _types.map((_) => HealthDataAccess.READ).toList();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final wasConnected = prefs.getBool('health_connected') ?? false;
    if (wasConnected) {
      state = state.copyWith(permissionsGranted: true);
      await fetchData();
    }
  }

  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    try {
      final health = Health();
      await health.configure();
      final granted = await health.requestAuthorization(_types, permissions: _permissions);
      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connected', true);
        state = state.copyWith(permissionsGranted: true, isLoading: false);
        await fetchData();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> fetchData() async {
    if (!state.permissionsGranted) return;
    state = state.copyWith(isLoading: true);
    try {
      final health = Health();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Today's steps
      final steps = await health.getTotalStepsInInterval(startOfDay, now);

      // Latest weight (last 30 days)
      final weightData = await health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );
      double? latestKg;
      if (weightData.isNotEmpty) {
        weightData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final val = weightData.first.value;
        if (val is NumericHealthValue) {
          latestKg = val.numericValue.toDouble();
        }
      }

      state = state.copyWith(
        todaySteps: steps,
        latestWeightKg: latestKg ?? state.latestWeightKg,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_connected', false);
    state = const HealthState();
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});
