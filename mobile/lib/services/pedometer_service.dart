import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps the Android step counter sensor for real-time step tracking.
///
/// The hardware sensor reports cumulative steps since last reboot.
/// We store a "baseline" at midnight so we can show today's steps.
class PedometerService {
  static const _baselineKey = 'pedometer_baseline_steps';
  static const _baselineDateKey = 'pedometer_baseline_date';

  static int _baseline = 0;
  static String _baselineDate = '';

  static Stream<int>? _stepsStream;

  /// Returns a stream of today's step count (updates in real-time).
  static Stream<int> get todayStepsStream {
    _stepsStream ??= Pedometer.stepCountStream
        .asyncMap((event) => _todaySteps(event.steps))
        .distinct();
    return _stepsStream!;
  }

  /// Converts raw cumulative sensor steps to today's count.
  static Future<int> _todaySteps(int rawSteps) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();

    if (_baselineDate != today) {
      // New day — reset baseline to current reading
      _baselineDate = today;
      _baseline = rawSteps;
      await prefs.setInt(_baselineKey, rawSteps);
      await prefs.setString(_baselineDateKey, today);
    }

    final todaySteps = rawSteps - _baseline;
    return todaySteps < 0 ? 0 : todaySteps;
  }

  /// Load persisted baseline on app start.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _baselineDate = prefs.getString(_baselineDateKey) ?? '';
    if (_baselineDate == today) {
      _baseline = prefs.getInt(_baselineKey) ?? 0;
    }
    // If it's a new day, baseline will reset on first step event.
  }
}
