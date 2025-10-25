import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// ✅ Initialize notifications and request permission
  static Future<void> init() async {
    tzData.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    // ✅ Request permissions (Android 13+, iOS)
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  /// ✅ Schedule notification (48h before due date or test delay)
  static Future<void> scheduleAssignmentReminder({
    required String title,
    required DateTime dueDate,
  }) async {
    final now = DateTime.now();

    // 🔹 For testing: show in 10 seconds
    final reminderTime = DateTime.now().add(const Duration(seconds: 10));

    // 🔹 For production: uncomment this instead
    // final reminderTime = dueDate.subtract(const Duration(hours: 48));

    if (reminderTime.isAfter(now)) {
      await _notifications.zonedSchedule(
        dueDate.hashCode, // unique ID
        'Upcoming Assignment Due!',
        '$title is due soon!',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'assignment_channel',
            'Assignment Reminders',
            channelDescription:
                'Reminds you before assignments are due.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // 🟢 For v19+, this replaces the old UILocalNotificationDateInterpretation param
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// ✅ Optional helper: cancel all notifications (for testing)
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}