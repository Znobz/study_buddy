import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../services/api_service.dart';

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

    // ✅ Request permissions but don't fail if exact alarms are denied
    await _requestNotificationPermissions();
  }

  /// Request notification permissions (graceful fallback)
  static Future<void> _requestNotificationPermissions() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      try {
        // Request notification permission (this usually works)
        final permissionGranted = await plugin.requestNotificationsPermission();
        print('🔔 Notification permission: $permissionGranted');

        // Try exact alarm permission (might be denied on emulator)
        final exactAlarmGranted = await plugin.requestExactAlarmsPermission();
        print('📅 Exact alarm permission: $exactAlarmGranted');

        if (permissionGranted == true) {
          print('✅ Basic notifications enabled');
        } else {
          print('⚠️ Notification permission denied');
        }

        if (exactAlarmGranted != true) {
          print('⚠️ Exact alarms not available (emulator limitation)');
          print('📱 Falling back to approximate scheduling');
        }
      } catch (e) {
        print('⚠️ Permission request error (emulator): $e');
        print('📱 Continuing with available permissions...');
      }
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      final enabled = await plugin.areNotificationsEnabled();
      return enabled ?? false;
    }
    return false;
  }

  /// Show an instant notification (for testing)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    // Check permission first
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('❌ Notifications are disabled');
      return;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Test notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails generalNotificationDetails =
    NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        0,
        title,
        body,
        generalNotificationDetails,
      );
      print('✅ Instant notification sent');
    } catch (e) {
      print('❌ Failed to show notification: $e');
    }
  }

  /// Schedule a notification (with fallback for emulators)
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Check permission first
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('❌ Notifications are disabled - cannot schedule');
      return false;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'assignment_reminders',
      'Assignment Reminders',
      channelDescription: 'Notifications for upcoming assignment due dates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      when: null,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    try {
      // Try exact scheduling first
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );

      print('✅ Notification scheduled for $scheduledTime with ID: $id');
      return true;
    } catch (e) {
      print('⚠️ Exact scheduling failed: $e');

      // Fallback: If scheduling is soon, show immediately
      final now = DateTime.now();
      final diffMinutes = scheduledTime.difference(now).inMinutes;

      if (diffMinutes <= 1) {
        print('📱 Showing immediate notification (fallback)');
        await showInstantNotification(title: title, body: body);
        return true;
      } else {
        print('❌ Cannot schedule notification for $diffMinutes minutes ahead');
        return false;
      }
    }
  }

  /// Cancel a specific notification by ID
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('✅ Cancelled notification with ID: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// Schedule assignment reminder with database tracking
  static Future<bool> scheduleAssignmentReminder({
    required int assignmentId,
    required String title,
    required DateTime reminderTime,
  }) async {
    // 1. Try to schedule local notification
    final localSuccess = await scheduleNotification(
      id: assignmentId,
      title: "📚 Assignment Reminder",
      body: "Don't forget about '$title'! It's due soon.",
      scheduledTime: reminderTime,
    );

    // 2. Save to database regardless of local scheduling success
    final dbSuccess = await _saveNotificationToDatabase(
      assignmentId: assignmentId,
      title: title,
      scheduledTime: reminderTime,
      status: localSuccess ? 'pending' : 'failed',
    );

    return dbSuccess; // Return database success for UI feedback
  }

  /// Save notification to database via API
  static Future<bool> _saveNotificationToDatabase({
    required int assignmentId,
    required String title,
    required DateTime scheduledTime,
    required String status,
  }) async {
    try {
      final api = ApiService();
      final result = await api.createNotification(
        assignmentId: assignmentId,
        title: title,
        message: "Don't forget about '$title'! It's due soon.",
        scheduledTime: scheduledTime,
        status: status,
      );

      print('✅ Notification saved to database: $result');
      return result != null;
    } catch (e) {
      print('❌ Failed to save notification to database: $e');
      return false;
    }
  }

  /// Get user's notifications from database
  static Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    try {
      final api = ApiService();
      final notifications = await api.getUserNotifications(userId);
      return notifications ?? [];
    } catch (e) {
      print('❌ Failed to get user notifications: $e');
      return [];
    }
  }

  /// Cancel notification (both local and database)
  static Future<bool> cancelNotificationById(int notificationId, int localNotificationId) async {
    try {
      // Cancel local notification
      await cancelNotification(localNotificationId);

      // Update database status
      final api = ApiService();
      final success = await api.updateNotificationStatus(notificationId, 'cancelled');

      print(success ? '✅ Notification cancelled' : '❌ Failed to cancel notification');
      return success;
    } catch (e) {
      print('❌ Error cancelling notification: $e');
      return false;
    }
  }

  /// Test notification system
  static Future<void> testNotificationSystem() async {
    print('🧪 Testing notification system...');

    final enabled = await areNotificationsEnabled();
    print('🔔 Notifications enabled: $enabled');

    if (enabled) {
      // Test 1: Immediate notification
      await showInstantNotification(
        title: "✅ Test 1: Immediate",
        body: "If you see this, basic notifications work!",
      );

      // Test 2: Short-term scheduled notification
      final futureTime = DateTime.now().add(const Duration(seconds: 10));
      final scheduled = await scheduleNotification(
        id: 9999,
        title: "✅ Test 2: Scheduled",
        body: "If you see this, scheduling works!",
        scheduledTime: futureTime,
      );

      if (scheduled) {
        print('📅 Test notification scheduled for 10 seconds from now');
      } else {
        print('⚠️ Scheduling failed - using fallback method');
      }
    } else {
      print('❌ Notifications disabled. Enable in Settings → Apps → Study Buddy → Notifications');
    }
  }

  /// Get scheduled notifications (for debugging)
  static Future<void> printScheduledNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Scheduled notifications: ${pending.length}');
      for (final notification in pending) {
        print('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
    }
  }
}