import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification system
  static Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);
  }

  /// Show an instant notification (for testing)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails generalNotificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      title,
      body,
      generalNotificationDetails,
    );
  }

  /// Schedule a notification at a specific time
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      0, // Notification ID
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, // ✅ required
      androidAllowWhileIdle: true, // ✅ still accepted
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Helper for assignment-specific reminders
  static Future<void> scheduleAssignmentReminder({
    required String title,
    required DateTime dueDate,
  }) async {
    // Schedule reminder 1 day before due date (or 10s from now if too close)
    final scheduledTime = dueDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    final reminderTime =
        scheduledTime.isAfter(now) ? scheduledTime : now.add(const Duration(seconds: 10));

    await scheduleNotification(
      title: "Upcoming Assignment Due!",
      body: "Your assignment '$title' is due soon!",
      scheduledTime: reminderTime,
    );
  }
}