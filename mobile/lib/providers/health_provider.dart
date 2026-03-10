import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fitbit_service.dart';
import '../services/google_fit_service.dart';
import '../services/pedometer_service.dart';

// Which source is driving the step count
enum StepSource { none, fitbit, googleFit, pedometer, manual }

class HealthState {
  final bool permissionsGranted; // Fitbit connected
  final bool googleFitConnected;
  final bool pedometerActive;
  final StepSource stepSource;
  final int? todaySteps;
  final int? todayCaloriesBurned;
  final int? todayActiveMinutes;
  final double? latestWeightKg;
  final bool isLoading;
  final String? errorMessage;
  final String? fitbitUserName;

  const HealthState({
    this.permissionsGranted = false,
    this.googleFitConnected = false,
    this.pedometerActive = false,
    this.stepSource = StepSource.none,
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
    bool? googleFitConnected,
    bool? pedometerActive,
    StepSource? stepSource,
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
        googleFitConnected: googleFitConnected ?? this.googleFitConnected,
        pedometerActive: pedometerActive ?? this.pedometerActive,
        stepSource: stepSource ?? this.stepSource,
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
  StreamSubscription<int>? _pedometerSub;
  final _fitbit = FitbitService();

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      if (state.permissionsGranted) fetchData();
      if (state.googleFitConnected) fetchGoogleFitData();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Fitbit ──────────────────────────────────────────────────────────────
    final fitbitConnected = prefs.getBool('fitbit_connected') ?? false;
    if (fitbitConnected) {
      state = state.copyWith(
        permissionsGranted: true,
        stepSource: StepSource.fitbit,
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
        }
        // If token is null, polling will retry — don't show error with cached data
      } catch (_) {
        // Network error on init — silent, polling will retry
      }
      _startFitbitPolling();
      return; // Fitbit takes priority — don't init other sources
    }

    // ── Google Fit ──────────────────────────────────────────────────────────
    final gfitConnected = prefs.getBool('google_fit_connected') ?? false;
    if (gfitConnected) {
      final ok = await GoogleFitService.signInSilently();
      if (ok) {
        state = state.copyWith(
          googleFitConnected: true,
          stepSource: StepSource.googleFit,
          todaySteps: prefs.getInt('gfit_steps'),
          todayCaloriesBurned: prefs.getInt('gfit_calories'),
        );
        await fetchGoogleFitData();
        _startGoogleFitPolling();
        return;
      } else {
        // Silent sign-in failed — mark disconnected
        await prefs.setBool('google_fit_connected', false);
      }
    }

    // ── Pedometer ───────────────────────────────────────────────────────────
    final pedoActive = prefs.getBool('pedometer_active') ?? false;
    if (pedoActive) {
      await _startPedometer();
      return;
    }

    // ── Manual / nothing ────────────────────────────────────────────────────
    await _loadManualSteps();
  }

  // ── Fitbit ────────────────────────────────────────────────────────────────

  void _startFitbitPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => fetchData());
  }

  Future<bool> requestPermissions() async {
    if (!_fitbit.isConfigured) {
      state = state.copyWith(
          errorMessage:
              'Fitbit Client ID not set. Add your Client ID in fitbit_service.dart.');
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
          stepSource: StepSource.fitbit,
          isLoading: false,
          fitbitUserName: name,
        );
        await fetchData();
        _startFitbitPolling();
        return true;
      }
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Fitbit login was cancelled or failed. Please try again.');
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Fitbit connection error: ${e.toString()}');
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
      final newCalories =
          summary?['activityCalories'] as int? ?? state.todayCaloriesBurned;
      final newMinutes =
          summary?['activeMinutes'] as int? ?? state.todayActiveMinutes;
      final newWeight = weightKg ?? state.latestWeightKg;

      state = state.copyWith(
        todaySteps: newSteps,
        todayCaloriesBurned: newCalories,
        todayActiveMinutes: newMinutes,
        latestWeightKg: newWeight,
        isLoading: false,
      );

      final prefs = await SharedPreferences.getInstance();
      if (newSteps != null) await prefs.setInt('fitbit_steps', newSteps);
      if (newCalories != null)
        await prefs.setInt('fitbit_calories_burned', newCalories);
      if (newMinutes != null)
        await prefs.setInt('fitbit_active_minutes', newMinutes);
      if (newWeight != null) await prefs.setDouble('fitbit_weight_kg', newWeight);
      // Persist daily history for trend graphs
      await _saveDailyHistory(prefs, steps: newSteps, burned: newCalories);
    } catch (e) {
      final msg = e.toString();
      // Silently ignore connectivity errors — keep showing cached data
      final isNetworkError = msg.contains('SocketException') ||
          msg.contains('SocketFailed') ||
          msg.contains('Failed host lookup') ||
          msg.contains('No address associated') ||
          msg.contains('errno = 7');
      // Never suppress token errors — show Reconnect prompt
      final suppress = isNetworkError;
      state = state.copyWith(
        isLoading: false,
        errorMessage: suppress ? null : msg.replaceFirst('Exception: ', ''),
        clearError: suppress,
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

  // ── Daily history persistence (for trend graphs) ─────────────────────────

  static String _todayDateStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveDailyHistory(SharedPreferences prefs,
      {int? steps, int? burned}) async {
    final day = _todayDateStr();
    if (steps != null) await prefs.setInt('steps_log_$day', steps);
    if (burned != null) await prefs.setInt('burned_log_$day', burned);
  }

  // ── Google Fit ────────────────────────────────────────────────────────────

  void _startGoogleFitPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => fetchGoogleFitData());
  }

  Future<bool> connectGoogleFit() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await GoogleFitService.signIn();
      if (!ok) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'Google Fit sign-in was cancelled.');
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_fit_connected', true);
      state = state.copyWith(
        googleFitConnected: true,
        stepSource: StepSource.googleFit,
        isLoading: false,
        clearError: true,
      );
      await fetchGoogleFitData();
      _startGoogleFitPolling();
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google Fit error: ${e.toString()}');
      return false;
    }
  }

  Future<void> fetchGoogleFitData() async {
    if (!state.googleFitConnected) return;
    try {
      final data = await GoogleFitService.fetchTodayData();
      if (data == null) return;
      final steps = data['steps'] as int?;
      final calories = data['calories'] as int?;
      state = state.copyWith(
        todaySteps: steps ?? state.todaySteps,
        todayCaloriesBurned: calories ?? state.todayCaloriesBurned,
      );
      final prefs = await SharedPreferences.getInstance();
      if (steps != null) await prefs.setInt('gfit_steps', steps);
      if (calories != null) await prefs.setInt('gfit_calories', calories);
      await _saveDailyHistory(prefs, steps: steps, burned: calories);
    } catch (_) {}
  }

  Future<void> disconnectGoogleFit() async {
    _pollTimer?.cancel();
    await GoogleFitService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_fit_connected', false);
    await prefs.remove('gfit_steps');
    await prefs.remove('gfit_calories');
    state = state.copyWith(
      googleFitConnected: false,
      stepSource: StepSource.none,
      todaySteps: null,
      todayCaloriesBurned: null,
    );
  }

  // ── Pedometer (real-time phone sensor) ────────────────────────────────────

  Future<void> _startPedometer() async {
    // Request ACTIVITY_RECOGNITION at runtime (required on Android 10+)
    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      state = state.copyWith(
        pedometerActive: false,
        stepSource: StepSource.none,
        errorMessage: 'Activity permission denied. Enable it in phone Settings to use the pedometer.',
      );
      return;
    }
    await PedometerService.init();
    _pedometerSub?.cancel();
    _pedometerSub = PedometerService.todayStepsStream.listen(
      (steps) {
        if (mounted) {
          state = state.copyWith(
            pedometerActive: true,
            stepSource: StepSource.pedometer,
            todaySteps: steps,
          );
          SharedPreferences.getInstance().then(
              (p) => _saveDailyHistory(p, steps: steps));
        }
      },
      onError: (_) {
        // Sensor not available or permission denied
        if (mounted) {
          state = state.copyWith(
            pedometerActive: false,
            stepSource: StepSource.none,
            errorMessage: 'Step sensor unavailable. Try manual entry.',
          );
        }
      },
    );
    state = state.copyWith(
        pedometerActive: true, stepSource: StepSource.pedometer);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pedometer_active', true);
  }

  Future<void> connectPedometer() async {
    await _startPedometer();
  }

  Future<void> disconnectPedometer() async {
    _pedometerSub?.cancel();
    _pedometerSub = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pedometer_active', false);
    state = state.copyWith(
      pedometerActive: false,
      stepSource: StepSource.none,
      todaySteps: null,
    );
  }

  // ── Manual entry ──────────────────────────────────────────────────────────

  Future<void> logManualSteps(int steps) async {
    if (state.permissionsGranted || state.googleFitConnected ||
        state.pedometerActive) return;
    final day = _todayDateStr();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('manual_steps_$day', steps);
    await _saveDailyHistory(prefs, steps: steps);
    state = state.copyWith(todaySteps: steps, stepSource: StepSource.manual);
  }

  Future<void> _loadManualSteps() async {
    final key =
        'manual_steps_${DateTime.now().toIso8601String().substring(0, 10)}';
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(key);
    if (saved != null) {
      state = state.copyWith(
          todaySteps: saved, stepSource: StepSource.manual);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pedometerSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>(
        (ref) => HealthNotifier());
