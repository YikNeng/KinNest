import 'dart:async';
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

  // Navigator key for navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  // Queue to store payload if navigation fails
  String? _pendingPayload;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    // Request notification permissions
    await _requestPermissions();

    // Android initialization with alarm settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Set up notification tap handler
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    var notificationStatus = await Permission.notification.request();

    // Request exact alarm permission
    var alarmStatus = await Permission.scheduleExactAlarm.request();
  }

  /// Handle notification tap (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    _navigateToAlarmScreen(response.payload);
  }

  /// Handle notification tap (background)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('Background notification tapped: ${response.payload}');
    // The navigation will be handled when app comes to foreground via initialRoute or pending intent
  }

  /// Navigate to alarm screen with Queue
  void _navigateToAlarmScreen(String? reminderId) {
    if (reminderId == null) return;

    // Check if the navigator is ready and attached to a view
    if (navigatorKey?.currentState?.mounted == true) {
      try {
        // Use GoRouter context if available, or fallback to standard Navigator
        if (navigatorKey!.currentContext != null) {
          navigatorKey!.currentContext!.push('/reminder-alarm/$reminderId');
          _pendingPayload = null; // Clear queue on success
        } else {
          _pendingPayload = reminderId;
        }
      } catch (e) {
        _pendingPayload = reminderId;
      }
    } else {
      _pendingPayload = reminderId;
    }
  }

  /// Process any queued navigation requests
  /// Call this from MyApp's build method (post frame callback)
  void processPendingNavigation() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload;
      _pendingPayload = null;

      // Attempt navigation again
      if (navigatorKey?.currentState?.mounted == true) {
        navigatorKey!.currentContext!.push('/reminder-alarm/$payload');
      } else {
        _pendingPayload = payload;
      }
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
      await initialize();
    }

    // Generate unique notification ID from reminder ID
    int notificationId = reminderId.hashCode;

    // Check if time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    // Android notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_alarms_v3', // Channel ID - MUST match the one in main.dart
          'Reminder Alarms', // Channel name
          channelDescription: 'Alarms for medication and appointment reminders',
          importance: Importance.max,
          priority: Priority.high,

          // SOUND CONFIGURATION
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alarm_sound'),
          audioAttributesUsage:
              AudioAttributesUsage.alarm, // Forces "Alarm" volume stream

          additionalFlags: Int32List.fromList(<int>[4]),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          fullScreenIntent: true, // Keep this for lock screen overlay
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,

          ongoing: false,
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
      DateTime now = DateTime.now();
      QuerySnapshot reminderSnapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('assignedTo', isEqualTo: userId)
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
          .where('isCompleted', isEqualTo: false)
          .get();

      print('Found ${reminderSnapshot.docs.length} upcoming reminders');

      int scheduledCount = 0;
      for (var doc in reminderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime scheduledTime = (data['scheduledTime'] as Timestamp).toDate();

        if (scheduledTime.isAfter(now)) {
          await scheduleReminderAlarm(
            reminderId: doc.id,
            title: data['title'] ?? 'Reminder',
            description: data['description'] ?? '',
            scheduledTime: scheduledTime,
            reminderType: data['type'] ?? 'general',
          );
          scheduledCount++;
        }
      }
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
    }
  }

  /// Check if a specific reminder alarm is scheduled
  Future<bool> isReminderAlarmScheduled(String reminderId) async {
    int notificationId = reminderId.hashCode;
    List<PendingNotificationRequest> pending = await _notifications
        .pendingNotificationRequests();
    return pending.any((notification) => notification.id == notificationId);
  }
}
