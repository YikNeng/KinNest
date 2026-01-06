import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';
import '../services/group_service.dart';

class ReminderListViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String groupId;

  // State variables
  List<Map<String, dynamic>> _reminders = [];
  Map<String, dynamic>? _groupData;
  String _filterMode = 'all'; // 'all', 'pending', 'completed'
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _expandedHistoryIds = {}; // Track which reminders show history

  // Getters
  List<Map<String, dynamic>> get reminders => _getFilteredReminders();
  String get filterMode => _filterMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasReminders => _reminders.isNotEmpty;
  String get currentUserId => _currentUserId;

  // Permission checks
  bool get isCaregiver => _groupData?['adminId'] == _currentUserId;
  bool get isElderly => !isCaregiver;
  bool get isMember {
    if (_groupData == null) return false;
    String adminId = _groupData!['adminId'];
    List<dynamic> memberIds = _groupData!['memberIds'] ?? [];
    return adminId == _currentUserId || memberIds.contains(_currentUserId);
  }

  ReminderListViewModel({required this.groupId}) {
    initializeGroupStream();
  }

  /// Get filtered reminders
  List<Map<String, dynamic>> _getFilteredReminders() {
    List<Map<String, dynamic>> filtered;

    switch (_filterMode) {
      case 'pending':
        filtered = _reminders
            .where(
              (r) =>
                  r['isCompleted'] != true &&
                  _reminderService.isOverdue(r) != true,
            )
            .toList();
        break;
      case 'completed':
        filtered = _reminders.where((r) => r['isCompleted'] == true).toList();
        break;
      case 'overdue':
        // Show only overdue reminders (not completed and past scheduled time)
        filtered = _reminders
            .where(
              (r) => r['isCompleted'] != true && _reminderService.isOverdue(r),
            )
            .toList();
        break;
      case 'all':
      default:
        filtered = _reminders;
    }

    // For elderly, only show reminders assigned to them
    if (isElderly) {
      filtered = filtered
          .where((r) => r['assignedTo'] == _currentUserId)
          .toList();
    }

    return filtered;
  }

  int get overdueCount {
    List<Map<String, dynamic>> overdue = _reminders
        .where((r) => r['isCompleted'] != true && _reminderService.isOverdue(r))
        .toList();
    if (isElderly) {
      overdue = overdue
          .where((r) => r['assignedTo'] == _currentUserId)
          .toList();
    }
    return overdue.length;
  }

  /// Set filter mode
  void setFilterMode(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  /// Get pending count
  int get pendingCount {
    List<Map<String, dynamic>> pending = _reminders
        .where(
          (r) =>
              r['isCompleted'] != true && _reminderService.isOverdue(r) != true,
        )
        .toList();
    if (isElderly) {
      pending = pending
          .where((r) => r['assignedTo'] == _currentUserId)
          .toList();
    }
    return pending.length;
  }

  /// Get completed count
  int get completedCount {
    List<Map<String, dynamic>> completed = _reminders
        .where((r) => r['isCompleted'] == true)
        .toList();
    if (isElderly) {
      completed = completed
          .where((r) => r['assignedTo'] == _currentUserId)
          .toList();
    }
    return completed.length;
  }

  /// Mark reminder as completed (with history)
  Future<bool> markReminderComplete(String reminderId) async {
    try {
      await _reminderService.markReminderCompleteWithHistory(
        reminderId,
        _currentUserId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Mark reminder as incomplete (undo)
  Future<bool> markReminderIncomplete(String reminderId) async {
    try {
      await _reminderService.markReminderIncompleteWithHistory(reminderId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Toggle completion (for elderly)
  Future<bool> toggleReminderCompletion(
    String reminderId,
    bool currentStatus,
  ) async {
    if (currentStatus) {
      // Try to undo (only works for one-time reminders)
      return await markReminderIncomplete(reminderId);
    } else {
      return await markReminderComplete(reminderId);
    }
  }

  /// Delete reminder (caregiver only)
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _reminderService.deleteReminder(reminderId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Refresh reminders
  Future<void> refresh() async {
    try {
      _reminders = await _reminderService.getGroupReminders(groupId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh reminders';
      notifyListeners();
    }
  }

  /// Toggle history expansion
  void toggleHistoryExpansion(String reminderId) {
    if (_expandedHistoryIds.contains(reminderId)) {
      _expandedHistoryIds.remove(reminderId);
    } else {
      _expandedHistoryIds.add(reminderId);
    }
    notifyListeners();
  }

  /// Check if history is expanded
  bool isHistoryExpanded(String reminderId) {
    return _expandedHistoryIds.contains(reminderId);
  }

  /// Get completion history
  List<Map<String, dynamic>> getCompletionHistory(
    Map<String, dynamic> reminder,
  ) {
    return _reminderService.getCompletionHistory(reminder);
  }

  /// Get completion count
  int getCompletionCount(Map<String, dynamic> reminder) {
    return _reminderService.getCompletionCount(reminder);
  }

  /// Get last completion date
  DateTime? getLastCompletionDate(Map<String, dynamic> reminder) {
    return _reminderService.getLastCompletionDate(reminder);
  }

  /// Format reminder time
  String formatReminderTime(Timestamp timestamp) {
    return _reminderService.formatReminderTime(timestamp);
  }

  /// Format completion date
  String formatCompletionDate(Timestamp timestamp) {
    return _reminderService.formatCompletionDate(timestamp);
  }

  /// Check if reminder is overdue
  bool isOverdue(Map<String, dynamic> reminder) {
    return _reminderService.isOverdue(reminder);
  }

  /// Get reminder type icon
  String getReminderTypeIcon(Map<String, dynamic> reminder) {
    return _reminderService.getReminderTypeIcon(reminder['type']);
  }

  /// Get reminder type color
  Color getReminderTypeColor(Map<String, dynamic> reminder) {
    String colorName = _reminderService.getReminderTypeColorName(
      reminder['type'],
    );
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

  /// Check if reminder is completed
  bool isReminderCompleted(Map<String, dynamic> reminder) {
    return reminder['isCompleted'] == true;
  }

  /// Check if reminder is recurring
  bool isRecurringReminder(Map<String, dynamic> reminder) {
    return _reminderService.isRecurringReminder(reminder);
  }

  /// Get next occurrence
  DateTime? getNextOccurrence(Map<String, dynamic> reminder) {
    return _reminderService.getNextOccurrence(reminder);
  }

  /// Get completion rate
  double getCompletionRate(Map<String, dynamic> reminder) {
    return _reminderService.getCompletionRate(reminder);
  }

  // Add these state variables
  Map<String, Map<String, dynamic>> _usersCache = {}; // Cache user data
  bool _isFetchingUsers = false;

  // Add these getters
  Map<String, Map<String, dynamic>> get usersCache => _usersCache;

  // Update the initializeGroupStream method to also fetch users
  void initializeGroupStream() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groupData = await _groupService.getGroupDetails(groupId);

      if (!isMember) {
        _errorMessage = 'You are not a member of this group';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _reminderService
          .getGroupRemindersStream(groupId)
          .listen(
            (reminders) {
              _reminders = reminders;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();

              // Fetch user details for assigned users
              _fetchAssignedUsers();
            },
            onError: (error) {
              _errorMessage = 'Failed to load reminders: $error';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Failed to load group data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user details for all assigned users in reminders
  // Fetch user details for all assigned users in reminders
  Future<void> _fetchAssignedUsers() async {
    if (_isFetchingUsers) return;

    _isFetchingUsers = true;

    try {
      // Get unique user IDs from reminders
      Set<String> userIds = {};
      for (var reminder in _reminders) {
        String? assignedTo = reminder['assignedTo'];
        if (assignedTo != null && !_usersCache.containsKey(assignedTo)) {
          userIds.add(assignedTo);
        }
      }

      if (userIds.isEmpty) {
        _isFetchingUsers = false;
        return;
      }

      // Batch fetch users
      Map<String, Map<String, dynamic>> users = await _reminderService
          .getUsersBatch(userIds.toList());

      // Update cache
      _usersCache.addAll(users);

      _isFetchingUsers = false;
      notifyListeners();
    } catch (e) {
      _isFetchingUsers = false;
    }
  }

  /// Get assigned user for a reminder
  Map<String, dynamic>? getAssignedUser(Map<String, dynamic> reminder) {
    String? assignedTo = reminder['assignedTo'];
    if (assignedTo == null) return null;

    return _usersCache[assignedTo];
  }

  /// Format assigned user display name
  String getAssignedUserName(Map<String, dynamic> reminder) {
    Map<String, dynamic>? user = getAssignedUser(reminder);
    return _reminderService.formatUserDisplayName(user);
  }

  /// Get assigned user initials
  String getAssignedUserInitials(Map<String, dynamic> reminder) {
    Map<String, dynamic>? user = getAssignedUser(reminder);
    return _reminderService.getUserInitials(user);
  }

  /// Check if user data is loaded
  bool isUserDataLoaded(String userId) {
    return _usersCache.containsKey(userId);
  }
}
