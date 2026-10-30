import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'habit_reminders';
  static const String channelName = 'Habit Reminders';
  static const String channelDesc =
      'Notifications to remind you to complete your daily habits';

  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;

    try {
      tz.initializeTimeZones();
      await _configureLocalTimeZone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

      // Create high-importance Android channel explicitly
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Configured local timezone: $timeZoneName');
    } catch (e) {
      debugPrint('Could not set timezone via FlutterTimezone: $e');
      try {
        final offset = DateTime.now().timeZoneOffset;
        final matched = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.local,
        );
        tz.setLocalLocation(matched);
        debugPrint('Fallback configured timezone to: ${matched.name}');
      } catch (_) {}
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
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
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await cancelHabitReminder(habitId);

      final parsed = _parseTime(timeString);
      if (parsed == null) return;

      // Ensure timezone is up to date
      final now = tz.TZDateTime.now(tz.local);
      final idHash = habitId.hashCode.abs() % 100000;

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
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

      // If scheduled time has already passed today, advance to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Check if device supports exact alarms without throwing
      var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          final canExact = await androidPlugin.canScheduleExactNotifications();
          if (canExact == true) {
            scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
          }
        } catch (_) {}
      }

      await _notificationsPlugin.zonedSchedule(
        idHash,
        'Habit Reminder 🌿',
        'Time to complete "$habitName"! Keep your streak alive!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
          'Scheduled reminder for $habitName at $scheduledDate (mode: $scheduleMode)');
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
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        99999,
        title,
        body,
        notificationDetails,
      );
      debugPrint('Instant notification shown successfully');
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
