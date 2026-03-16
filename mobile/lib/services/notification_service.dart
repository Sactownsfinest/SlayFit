import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
  // Water reminders: IDs 100–108 for hours 9–17
  // Move reminders:  IDs 200–208 for hours 9–17
  static const int _waterBaseId = 100;
  static const int _moveBaseId = 200;
  static const int _missedLogId = 300;
  static const List<int> _reminderHours = [9, 10, 11, 12, 13, 14, 15, 16, 17];

  static const List<String> _moveMessages = [
    'You haven\'t moved in a while — maybe stretch your legs! 🚶',
    'Time for a quick walk! Even 5 minutes makes a difference. 💪',
    'Get up and move! Your body\'ll thank you later. 🏃',
    'Step break! Stand up, stretch, take a lap around the room. 🌟',
    'Move it! A short stroll helps hit that step goal. 👟',
    'Body check — haven\'t moved in a bit. Time to stretch! 💫',
    'Quick move break! A few minutes of walking counts. 🔥',
    'Stand up and get those legs moving! You\'ve got this. ⚡',
    'Let\'s go! A brisk walk now keeps you on track. 🏋️',
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

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
    if (prefs.getBool('water_reminder_enabled') ?? false) {
      await scheduleWaterReminders();
    }
    if (prefs.getBool('move_reminder_enabled') ?? false) {
      await scheduleMoveReminders();
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

  Future<void> scheduleWaterReminders() async {
    await cancelWaterReminders();
    for (int i = 0; i < _reminderHours.length; i++) {
      await _plugin.zonedSchedule(
        _waterBaseId + i,
        'Time to hydrate! 💧',
        'Drink a glass of water and stay on top of your daily goal.',
        _nextInstanceOf(_reminderHours[i], 0),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminder_enabled', true);
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < _reminderHours.length; i++) {
      await _plugin.cancel(_waterBaseId + i);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminder_enabled', false);
  }

  Future<void> scheduleMoveReminders() async {
    await cancelMoveReminders();
    for (int i = 0; i < _reminderHours.length; i++) {
      await _plugin.zonedSchedule(
        _moveBaseId + i,
        'Time to move! 🏃',
        _moveMessages[i],
        _nextInstanceOf(_reminderHours[i], 30),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('move_reminder_enabled', true);
  }

  Future<void> cancelMoveReminders() async {
    for (int i = 0; i < _reminderHours.length; i++) {
      await _plugin.cancel(_moveBaseId + i);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('move_reminder_enabled', false);
  }

  Future<void> scheduleMissedLogReminder(TimeOfDay time) async {
    await cancelMissedLogReminder();
    await _plugin.zonedSchedule(
      _missedLogId,
      "Don't break your streak! 🔥",
      'Log your meals to keep your streak alive.',
      _nextInstanceOf(time.hour, time.minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMissedLogReminder() async {
    await _plugin.cancel(_missedLogId);
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

  /// Show an immediate push notification for a nudge received from another user.
  Future<void> showNudgeNotification({
    required String fromName,
    required String challengeName,
  }) async {
    await _plugin.show(
      400 + DateTime.now().millisecondsSinceEpoch % 1000,
      '👊 $fromName nudged you!',
      'Get moving on "$challengeName" — your squad is watching!',
      _notificationDetails(),
    );
  }
}
