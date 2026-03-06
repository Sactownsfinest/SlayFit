import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'slayfit_reminders';
  static const String _channelName = 'SlayFit Reminders';
  static const int _lunchId = 1;
  static const int _eveningId = 2;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Reschedule any saved reminders
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('lunch_reminder_enabled') ?? false) {
      final hour = prefs.getInt('lunch_reminder_hour') ?? 12;
      final minute = prefs.getInt('lunch_reminder_minute') ?? 0;
      await scheduleLunchReminder(TimeOfDay(hour: hour, minute: minute));
    }
    if (prefs.getBool('evening_reminder_enabled') ?? false) {
      final hour = prefs.getInt('evening_reminder_hour') ?? 20;
      final minute = prefs.getInt('evening_reminder_minute') ?? 0;
      await scheduleEveningReminder(TimeOfDay(hour: hour, minute: minute));
    }
  }

  Future<void> scheduleLunchReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      _lunchId,
      'Time to eat! 🥗',
      'Don\'t forget to log your lunch and stay on track.',
      _nextInstanceOf(time.hour, time.minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleEveningReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      _eveningId,
      'Evening check-in 💪',
      'How did today go? Log your remaining meals and activities.',
      _nextInstanceOf(time.hour, time.minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelLunchReminder() async {
    await _plugin.cancel(_lunchId);
  }

  Future<void> cancelEveningReminder() async {
    await _plugin.cancel(_eveningId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }
}
