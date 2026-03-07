import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fitbit_service.dart';

class HealthState {
  final bool permissionsGranted;
  final int? todaySteps;
  final int? todayCaloriesBurned;
  final int? todayActiveMinutes;
  final double? latestWeightKg;
  final bool isLoading;
  final String? errorMessage;
  final String? fitbitUserName;

  const HealthState({
    this.permissionsGranted = false,
    this.todaySteps,
    this.todayCaloriesBurned,
    this.todayActiveMinutes,
    this.latestWeightKg,
    this.isLoading = false,
    this.errorMessage,
    this.fitbitUserName,
  });

  HealthState copyWith({
    bool? permissionsGranted,
    int? todaySteps,
    int? todayCaloriesBurned,
    int? todayActiveMinutes,
    double? latestWeightKg,
    bool? isLoading,
    String? errorMessage,
    String? fitbitUserName,
    bool clearError = false,
  }) =>
      HealthState(
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        todaySteps: todaySteps ?? this.todaySteps,
        todayCaloriesBurned: todayCaloriesBurned ?? this.todayCaloriesBurned,
        todayActiveMinutes: todayActiveMinutes ?? this.todayActiveMinutes,
        latestWeightKg: latestWeightKg ?? this.latestWeightKg,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        fitbitUserName: fitbitUserName ?? this.fitbitUserName,
      );
}

class HealthNotifier extends StateNotifier<HealthState>
    with WidgetsBindingObserver {
  HealthNotifier() : super(const HealthState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Timer? _pollTimer;
  final _fitbit = FitbitService();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.permissionsGranted) {
      fetchData();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final wasConnected = prefs.getBool('fitbit_connected') ?? false;
    if (wasConnected) {
      // Restore last known values immediately so UI shows cached data right away
      state = state.copyWith(
        permissionsGranted: true,
        todaySteps: prefs.getInt('fitbit_steps'),
        todayCaloriesBurned: prefs.getInt('fitbit_calories_burned'),
        todayActiveMinutes: prefs.getInt('fitbit_active_minutes'),
        latestWeightKg: prefs.getDouble('fitbit_weight_kg'),
        fitbitUserName: prefs.getString('fitbit_display_name'),
      );
      try {
        final token = await _fitbit.getValidAccessToken();
        if (token != null) {
          await fetchData();
          _startPolling();
        } else {
          // Token refresh failed — keep cached data visible, show reconnect prompt
          state = state.copyWith(
            errorMessage: 'Fitbit session expired. Please reconnect.',
          );
        }
      } catch (_) {
        // Network error on startup — keep cached data, retry on next foreground
        state = state.copyWith(
          errorMessage: 'Could not reach Fitbit. Will retry when online.',
        );
        _startPolling(); // Keep polling so it recovers automatically
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Poll every 60 seconds — Fitbit tracker syncs ~every 1-2 min via Bluetooth
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => fetchData());
  }

  Future<bool> requestPermissions() async {
    if (!_fitbit.isConfigured) {
      state = state.copyWith(
        errorMessage:
            'Fitbit Client ID not set. Add your Client ID in fitbit_service.dart.',
      );
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _fitbit.authenticate();
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('fitbit_connected', true);
        final name = await _fitbit.fetchDisplayName();
        if (name != null) await prefs.setString('fitbit_display_name', name);
        state = state.copyWith(
          permissionsGranted: true,
          isLoading: false,
          fitbitUserName: name,
        );
        await fetchData();
        _startPolling();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Fitbit login was cancelled or failed. Please try again.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Fitbit connection error: ${e.toString()}',
      );
    }
    return false;
  }

  Future<void> fetchData() async {
    if (!state.permissionsGranted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _fitbit.fetchTodayActivitySummary(),
        _fitbit.fetchLatestWeightKg(),
      ]);
      final summary = results[0] as Map<String, dynamic>?;
      final weightKg = results[1] as double?;

      final newSteps = summary?['steps'] as int? ?? state.todaySteps;
      final newCalories = summary?['activityCalories'] as int? ?? state.todayCaloriesBurned;
      final newMinutes = summary?['activeMinutes'] as int? ?? state.todayActiveMinutes;
      final newWeight = weightKg ?? state.latestWeightKg;

      state = state.copyWith(
        todaySteps: newSteps,
        todayCaloriesBurned: newCalories,
        todayActiveMinutes: newMinutes,
        latestWeightKg: newWeight,
        isLoading: false,
      );

      // Persist so data survives app restarts
      final prefs = await SharedPreferences.getInstance();
      if (newSteps != null) await prefs.setInt('fitbit_steps', newSteps);
      if (newCalories != null) await prefs.setInt('fitbit_calories_burned', newCalories);
      if (newMinutes != null) await prefs.setInt('fitbit_active_minutes', newMinutes);
      if (newWeight != null) await prefs.setDouble('fitbit_weight_kg', newWeight);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    await _fitbit.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fitbit_connected', false);
    await prefs.remove('fitbit_steps');
    await prefs.remove('fitbit_calories_burned');
    await prefs.remove('fitbit_active_minutes');
    await prefs.remove('fitbit_weight_kg');
    await prefs.remove('fitbit_display_name');
    state = const HealthState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});
