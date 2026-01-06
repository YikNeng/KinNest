import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';

class CaregiverHomeViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // State variables
  Map<String, dynamic>? _nearestReminder;
  bool _isLoading = true;
  String? _errorMessage;
  String? _caregiverName;

  // Getters
  Map<String, dynamic>? get nearestReminder => _nearestReminder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUpcomingReminder => _nearestReminder != null;
  String get caregiverName => _caregiverName ?? 'Caregiver';

  // Reminder details getters
  String get reminderTitle => _nearestReminder?['title'] ?? 'Untitled';
  String get reminderDescription => _nearestReminder?['description'] ?? '';
  String get assignedUserName =>
      _nearestReminder?['assignedUserName'] ?? 'Unknown';
  String get assignedUserEmail => _nearestReminder?['assignedUserEmail'] ?? '';
  String get groupName => _nearestReminder?['groupName'] ?? 'Unknown Group';
  String get groupId => _nearestReminder?['groupId'] ?? '';
  String get reminderId => _nearestReminder?['reminderId'] ?? '';

  Timestamp? get scheduledTime => _nearestReminder?['scheduledTime'];
  String get reminderType => _nearestReminder?['type'] ?? 'normal';
  String get repeatType => _nearestReminder?['repeatType'] ?? 'once';

  CaregiverHomeViewModel() {
    _initialize();
  }

  /// Initialize - fetch caregiver name and nearest reminder
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch caregiver name
      await _fetchCaregiverName();

      // Fetch nearest upcoming reminder
      await _fetchNearestReminder();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch caregiver name
  Future<void> _fetchCaregiverName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _caregiverName = userData['name'] ?? 'Caregiver';
      }
    } catch (e) {
      // Ignore, use default name
    }
  }

  /// Fetch nearest upcoming reminder
  Future<void> _fetchNearestReminder() async {
    try {
      _nearestReminder = await _reminderService.getNearestUpcomingReminder(
        _currentUserId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load upcoming reminders';
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await _initialize();
  }

  /// Get reminder type icon
  String getReminderTypeIcon() {
    return _reminderService.getReminderTypeIcon(reminderType);
  }

  /// Get reminder type color
  Color getReminderTypeColor() {
    String colorName = _reminderService.getReminderTypeColorName(reminderType);
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get reminder type display name
  String getReminderTypeDisplayName() {
    return _reminderService.getReminderTypeDisplayName(reminderType);
  }

  /// Get repeat type display name
  String getRepeatTypeDisplayName() {
    return _reminderService.getRepeatTypeDisplayName(repeatType);
  }

  /// Check if reminder is recurring
  bool get isRecurring {
    return repeatType.toLowerCase() != 'once';
  }

  /// Format scheduled time
  String formatScheduledTime() {
    if (scheduledTime == null) return '';
    return _reminderService.formatReminderTime(scheduledTime!);
  }

  /// Get time until reminder
  String getTimeUntilReminder() {
    if (scheduledTime == null) return '';
    return _reminderService.getTimeUntilReminder(scheduledTime!);
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
}
