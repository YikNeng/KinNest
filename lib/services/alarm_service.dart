import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  // CRITICAL: Navigator key for navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing AlarmService...');

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    print('✅ Timezone initialized: Asia/Kuala_Lumpur');

    // Request notification permissions
    await _requestPermissions();

    // Android initialization with alarm settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // CRITICAL: Set up notification tap handler
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _isInitialized = true;
    print('✅ AlarmService initialized successfully');
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    print('🔐 Requesting permissions...');

    // Request notification permission
    var notificationStatus = await Permission.notification.request();
    print(
      '  Notification permission: ${notificationStatus.isGranted ? "✅ Granted" : "❌ Denied"}',
    );

    // Request exact alarm permission (Android 12+)
    var alarmStatus = await Permission.scheduleExactAlarm.request();
    print(
      '  Exact alarm permission: ${alarmStatus.isGranted ? "✅ Granted" : "❌ Denied"}',
    );
  }

  /// Handle notification tap (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    _navigateToAlarmScreen(response.payload);
  }

  /// Handle notification tap (background) - MUST be static top-level or static method
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('🔔 Background notification tapped: ${response.payload}');
    // The navigation will be handled when app comes to foreground
  }

  /// Navigate to alarm screen
  void _navigateToAlarmScreen(String? reminderId) {
    if (reminderId != null && navigatorKey?.currentContext != null) {
      print('🚀 Navigating to alarm screen for reminder: $reminderId');
      navigatorKey!.currentContext!.push('/reminder-alarm/$reminderId');
    } else {
      print(
        '❌ Cannot navigate: reminderId=$reminderId, context=${navigatorKey?.currentContext != null}',
      );
    }
  }

  /// Schedule a reminder alarm
  Future<void> scheduleReminderAlarm({
    required String reminderId,
    required String title,
    required String description,
    required DateTime scheduledTime,
    required String reminderType,
  }) async {
    if (!_isInitialized) {
      print('⚠️ AlarmService not initialized, initializing now...');
      await initialize();
    }

    print('\n📅 Scheduling alarm:');
    print('  ID: $reminderId');
    print('  Title: $title');
    print('  Time: $scheduledTime');
    print('  Type: $reminderType');

    // Generate unique notification ID from reminder ID
    int notificationId = reminderId.hashCode;
    print('  Notification ID: $notificationId');

    // Check if time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ Scheduled time is in the past, not scheduling alarm');
      return;
    }

    // Android notification details with FULL SCREEN INTENT
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_alarms', // Channel ID - MUST match the one in main.dart
          'Reminder Alarms', // Channel name
          channelDescription: 'Alarms for medication and appointment reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),

          // CRITICAL: These settings make it show as full-screen alarm
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,

          // Make it persistent
          ongoing: false, // Set to false so user can dismiss after seeing
          autoCancel: false,

          // Actions
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'view',
              'View',
              showsUserInterface: true,
            ),
          ],
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Convert DateTime to TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    print('  TZ Scheduled time: $scheduledDate');

    try {
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        '${_getReminderIcon(reminderType)} $title',
        description.isNotEmpty ? description : 'Tap to view details',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: reminderId, // Pass reminder ID for navigation
      );

      print('✅ Alarm scheduled successfully!');

      // Verify it was scheduled
      await Future.delayed(const Duration(milliseconds: 500));
      bool isScheduled = await isReminderAlarmScheduled(reminderId);
      print(
        '  Verification: ${isScheduled ? "✅ Confirmed in pending" : "❌ NOT in pending!"}',
      );
    } catch (e) {
      print('❌ Error scheduling alarm: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled reminder alarm
  Future<void> cancelReminderAlarm(String reminderId) async {
    int notificationId = reminderId.hashCode;
    await _notifications.cancel(notificationId);
    print('🔕 Alarm cancelled for $reminderId (ID: $notificationId)');
  }

  /// Cancel all alarms
  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    print('🔕 All alarms cancelled');
  }

  /// Get reminder type icon
  String _getReminderIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return '💊';
      case 'appointment':
        return '📅';
      default:
        return '🔔';
    }
  }

  /// Schedule all pending reminders for a user
  Future<void> scheduleAllUserReminders(String userId) async {
    print('\n📋 Scheduling all reminders for user: $userId');

    try {
      // Get all upcoming reminders for the user
      DateTime now = DateTime.now();
      QuerySnapshot reminderSnapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('assignedTo', isEqualTo: userId)
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
          .where('isCompleted', isEqualTo: false)
          .get();

      print('Found ${reminderSnapshot.docs.length} upcoming reminders');

      int scheduledCount = 0;
      int skippedCount = 0;

      // Schedule each reminder
      for (var doc in reminderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime scheduledTime = (data['scheduledTime'] as Timestamp).toDate();

        // Only schedule if in future
        if (scheduledTime.isAfter(now)) {
          await scheduleReminderAlarm(
            reminderId: doc.id,
            title: data['title'] ?? 'Reminder',
            description: data['description'] ?? '',
            scheduledTime: scheduledTime,
            reminderType: data['type'] ?? 'normal',
          );
          scheduledCount++;
        } else {
          skippedCount++;
        }
      }

      print(
        '✅ Scheduling complete: $scheduledCount scheduled, $skippedCount skipped',
      );
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
    }
  }

  /// Get all pending notification IDs
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if a specific reminder alarm is scheduled
  Future<bool> isReminderAlarmScheduled(String reminderId) async {
    int notificationId = reminderId.hashCode;
    List<PendingNotificationRequest> pending = await getPendingNotifications();
    return pending.any((notification) => notification.id == notificationId);
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String reminderId,
    required String title,
    required String description,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    int notificationId = reminderId.hashCode;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_alarms',
          'Reminder Alarms',
          channelDescription: 'Alarms for medication and appointment reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      description,
      notificationDetails,
      payload: reminderId,
    );

    print('🔔 Immediate notification shown: $title');
  }
}
