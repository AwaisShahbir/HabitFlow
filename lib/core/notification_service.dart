import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('requestPermissions error: $e');
    }
    return false;
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String timeString,
    required List<int> scheduledDays,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      await cancelHabitReminder(habitId);

      final parsed = _parseTime(timeString);
      if (parsed == null) return;

      final now = tz.TZDateTime.now(tz.local);
      final idHash = habitId.hashCode.abs() % 100000;

      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications to remind you to complete your daily habits',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsed.hour,
        parsed.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        idHash,
        'Habit Reminder 🌿',
        'Time to complete "$habitName"! Keep your streak alive!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling reminder for $habitName: $e');
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (kIsWeb || !_isInitialized) return;
    try {
      final idHash = habitId.hashCode.abs() % 100000;
      await _notificationsPlugin.cancel(idHash);
    } catch (e) {
      debugPrint('Error canceling reminder: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb || !_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all reminders: $e');
    }
  }

  Future<void> showInstantNotification({
    String title = 'HabitFlow Reminder 🌿',
    String body = 'Keep your streak alive! You have habits pending today.',
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await requestPermissions();
      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications to remind you to complete your daily habits',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        99999,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}

