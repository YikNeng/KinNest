import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/alarm_service.dart';

class ElderlyHomeViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final AlarmService _alarmService = AlarmService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // State
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _nearestReminder;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  // Getters
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get nearestReminder => _nearestReminder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => _userData?['name'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';

  ElderlyHomeViewModel() {
    _initialize();
  }

  /// Initialize - Load user data and nearest reminder
  Future<void> _initialize() async {
    if (_isDisposed) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user data
      _userData = await _userService.getUserProfile(_currentUserId);

      if (_userData != null) {
        // Fetch nearest reminder
        await _fetchNearestReminder();

        // ✅ SCHEDULE ALL PENDING REMINDERS
        await _alarmService.scheduleAllUserReminders(_currentUserId);
      }

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Fetch nearest upcoming reminder
  Future<void> _fetchNearestReminder() async {
    if (_isDisposed) return;

    try {
      DateTime now = DateTime.now();

      QuerySnapshot reminderSnapshot = await _firestore
          .collection('reminders')
          .where('assignedTo', isEqualTo: _currentUserId)
          .where('isCompleted', isEqualTo: false)
          .where(
            'scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .orderBy('scheduledTime', descending: false)
          .limit(1)
          .get();

      if (reminderSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> reminderData =
            reminderSnapshot.docs.first.data() as Map<String, dynamic>;
        reminderData['reminderId'] = reminderSnapshot.docs.first.id;

        if (!_isDisposed) {
          _nearestReminder = reminderData;
        }
      } else {
        if (!_isDisposed) {
          _nearestReminder = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching nearest reminder: $e');
      if (!_isDisposed) {
        _nearestReminder = null;
      }
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    if (_isDisposed) return;
    await _initialize();
  }

  /// Format time until reminder
  String formatTimeUntil(Map<String, dynamic>? reminder) {
    if (reminder == null) return 'No upcoming reminders';

    try {
      Timestamp scheduledTime = reminder['scheduledTime'];
      DateTime scheduledDateTime = scheduledTime.toDate();
      DateTime now = DateTime.now();

      Duration difference = scheduledDateTime.difference(now);

      if (difference.isNegative) {
        return 'Past due';
      }

      if (difference.inDays > 0) {
        return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Format scheduled time
  String formatScheduledTime(Map<String, dynamic>? reminder) {
    if (reminder == null) return '';

    try {
      Timestamp scheduledTime = reminder['scheduledTime'];
      DateTime dateTime = scheduledTime.toDate();

      String date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      String time = _formatTime(dateTime);

      return '$date at $time';
    } catch (e) {
      return 'Unknown time';
    }
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  /// Get reminder type icon
  IconData getReminderIcon(String? type) {
    if (type == null) return Icons.notifications;

    switch (type.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  /// Get reminder type color
  Color getReminderColor(String? type) {
    if (type == null) return Colors.orange;

    switch (type.toLowerCase()) {
      case 'medication':
        return Colors.red;
      case 'appointment':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  /// Get greeting based on time of day
  String getGreeting() {
    int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  /// Clear error message
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
