import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/reminder_service.dart';
import '../services/group_service.dart';

class CaregiverReminderViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // State
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _reminders = [];
  Map<String, String> _elderlyNames = {}; // Cache elderly names
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get groups => _groups;
  Map<String, dynamic>? get selectedGroup => _selectedGroup;
  List<Map<String, dynamic>> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CaregiverReminderViewModel() {
    _initialize();
  }

  /// Initialize - load groups and reminders
  Future<void> _initialize() async {
    await loadGroups();
  }

  /// Load all groups for the caregiver
  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch groups where caregiver is admin
      QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('adminId', isEqualTo: _currentUserId)
          .get();

      _groups = groupSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['groupId'] = doc.id;
        return data;
      }).toList();

      if (_groups.isNotEmpty) {
        // Auto-select first group
        _selectedGroup = _groups.first;
        await loadRemindersForSelectedGroup();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change selected group
  Future<void> selectGroup(Map<String, dynamic> group) async {
    if (_selectedGroup?['groupId'] == group['groupId']) {
      return; // Already selected
    }

    _selectedGroup = group;
    _reminders = []; // Clear old reminders
    _elderlyNames = {}; // Clear cached names
    notifyListeners();

    await loadRemindersForSelectedGroup();
  }

  /// Load reminders for currently selected group
  Future<void> loadRemindersForSelectedGroup() async {
    if (_selectedGroup == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String groupId = _selectedGroup!['groupId'];

      // Fetch all upcoming reminders for the selected group
      _reminders = await _reminderService.getAllUpcomingRemindersForGroup(
        groupId,
      );

      // Pre-fetch elderly names
      await _prefetchElderlyNames();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pre-fetch elderly names
  Future<void> _prefetchElderlyNames() async {
    Set<String> uniqueElderlyIds = {};

    for (var reminder in _reminders) {
      String? assignedTo = reminder['assignedTo'];
      if (assignedTo != null) {
        uniqueElderlyIds.add(assignedTo);
      }
    }

    for (String elderlyId in uniqueElderlyIds) {
      if (!_elderlyNames.containsKey(elderlyId)) {
        String name = await _reminderService.getElderlyDisplayName(elderlyId);
        _elderlyNames[elderlyId] = name;
      }
    }
  }

  /// Get elderly user name from cache
  String getElderlyName(String elderlyId) {
    return _elderlyNames[elderlyId] ?? 'Loading...';
  }

  /// Get icon for reminder type
  IconData getReminderIcon(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'normal':
      default:
        return Icons.notifications;
    }
  }

  /// Get color for reminder type
  Color getReminderColor(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return Colors.red;
      case 'appointment':
        return Colors.blue;
      case 'normal':
      default:
        return Colors.orange;
    }
  }

  /// Format scheduled time for display
  String formatScheduledTime(Timestamp scheduledTime) {
    DateTime scheduled = scheduledTime.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime reminderDate = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
    );

    String timeStr = _formatTime(scheduled);

    if (reminderDate == today) {
      return 'Today at $timeStr';
    } else if (reminderDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${_formatDate(scheduled)} at $timeStr';
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Refresh reminders
  Future<void> refresh() async {
    await loadRemindersForSelectedGroup();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
