import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';
import '../services/group_service.dart';

class ReminderViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Stream subscription (not currently used, but kept for potential future use)
  StreamSubscription<List<Map<String, dynamic>>>? _remindersSubscription;

  // Disposal tracking
  bool _isDisposed = false;

  // State
  String? _userRole; // 'caregiver' or 'elderly'
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _allReminders = [];
  Map<String, Map<String, dynamic>> _usersCache = {};
  String _filterMode = 'upcoming'; // 'upcoming' or 'past'
  bool _isLoading = false;
  bool _isFetchingUsers = false;
  String? _errorMessage;

  // Getters
  String? get userRole => _userRole;
  bool get isCaregiver => _userRole == 'caregiver';
  bool get isElderly => _userRole == 'elderly';
  List<Map<String, dynamic>> get groups => _groups;
  Map<String, dynamic>? get selectedGroup => _selectedGroup;
  List<Map<String, dynamic>> get reminders => _getFilteredReminders();
  String get filterMode => _filterMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReminderViewModel() {
    _initialize();
  }

  /// Initialize - detect role and load appropriate data
  Future<void> _initialize() async {
    if (_isDisposed) return;

    await _detectUserRole();
    await loadGroups();
  }

  /// Detect user role from Firestore
  Future<void> _detectUserRole() async {
    if (_isDisposed) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && !_isDisposed) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userRole = userData['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error detecting user role: $e');
    }
  }

  /// Load groups based on user role
  Future<void> loadGroups() async {
    if (_isDisposed) return;

    _isLoading = true;
    _errorMessage = null;

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      if (isCaregiver) {
        // Caregiver: Load groups where user is admin
        await _loadCaregiverGroups();
      } else if (isElderly) {
        // Elderly: Load groups where user is a member
        await _loadElderlyGroups();
      }

      if (!_isDisposed) {
        if (_groups.isNotEmpty) {
          // Auto-select first group
          _selectedGroup = _groups.first;
          await loadRemindersForSelectedGroup();
        } else {
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load groups for caregiver (where they are admin)
  Future<void> _loadCaregiverGroups() async {
    if (_isDisposed) return;

    QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('adminId', isEqualTo: _currentUserId)
        .get();

    if (!_isDisposed) {
      _groups = groupSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['groupId'] = doc.id;
        return data;
      }).toList();
    }
  }

  /// Load groups for elderly (where they are a member)
  Future<void> _loadElderlyGroups() async {
    if (_isDisposed) return;

    QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: _currentUserId)
        .get();

    if (!_isDisposed) {
      _groups = groupSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['groupId'] = doc.id;
        return data;
      }).toList();
    }
  }

  /// Change selected group
  Future<void> selectGroup(Map<String, dynamic> group) async {
    if (_isDisposed) return;

    if (_selectedGroup?['groupId'] == group['groupId']) {
      return; // Already selected
    }

    _selectedGroup = group;
    _allReminders = [];
    _usersCache = {};

    if (!_isDisposed) {
      notifyListeners();
    }

    await loadRemindersForSelectedGroup();
  }

  /// Load reminders for currently selected group
  Future<void> loadRemindersForSelectedGroup() async {
    if (_isDisposed || _selectedGroup == null) return;

    _isLoading = true;
    _errorMessage = null;

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      String groupId = _selectedGroup!['groupId'];

      // Fetch ALL reminders for the selected group
      _allReminders = await _reminderService.getGroupReminders(groupId);

      // Pre-fetch user data
      await _fetchAssignedUsers();

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Get filtered reminders based on filter mode and user role
  List<Map<String, dynamic>> _getFilteredReminders() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filtered;

    if (_filterMode == 'upcoming') {
      // Show reminders with scheduledTime >= now
      filtered =
          _allReminders.where((reminder) {
            Timestamp scheduledTime = reminder['scheduledTime'];
            return scheduledTime.toDate().isAfter(now) ||
                scheduledTime.toDate().isAtSameMomentAs(now);
          }).toList()..sort((a, b) {
            Timestamp timeA = a['scheduledTime'];
            Timestamp timeB = b['scheduledTime'];
            return timeA.compareTo(timeB);
          });
    } else {
      // 'past' - Show reminders with scheduledTime < now
      filtered =
          _allReminders.where((reminder) {
            Timestamp scheduledTime = reminder['scheduledTime'];
            return scheduledTime.toDate().isBefore(now);
          }).toList()..sort((a, b) {
            Timestamp timeA = a['scheduledTime'];
            Timestamp timeB = b['scheduledTime'];
            return timeB.compareTo(timeA); // Most recent first for past
          });
    }

    // FOR ELDERLY: Filter to only show reminders assigned to them
    if (isElderly) {
      filtered = filtered
          .where((reminder) => reminder['assignedTo'] == _currentUserId)
          .toList();
    }

    return filtered;
  }

  /// Set filter mode
  void setFilterMode(String mode) {
    if (_isDisposed) return;

    _filterMode = mode;
    notifyListeners();
  }

  /// Get upcoming count (role-aware)
  int get upcomingCount {
    DateTime now = DateTime.now();
    var upcoming = _allReminders.where((reminder) {
      Timestamp scheduledTime = reminder['scheduledTime'];
      return scheduledTime.toDate().isAfter(now) ||
          scheduledTime.toDate().isAtSameMomentAs(now);
    });

    // For elderly, only count their reminders
    if (isElderly) {
      upcoming = upcoming.where((r) => r['assignedTo'] == _currentUserId);
    }

    return upcoming.length;
  }

  /// Get past count (role-aware)
  int get pastCount {
    DateTime now = DateTime.now();
    var past = _allReminders.where((reminder) {
      Timestamp scheduledTime = reminder['scheduledTime'];
      return scheduledTime.toDate().isBefore(now);
    });

    // For elderly, only count their reminders
    if (isElderly) {
      past = past.where((r) => r['assignedTo'] == _currentUserId);
    }

    return past.length;
  }

  /// Fetch user details for all assigned users in reminders
  Future<void> _fetchAssignedUsers() async {
    if (_isDisposed || _isFetchingUsers) return;

    _isFetchingUsers = true;

    try {
      Set<String> userIds = {};
      for (var reminder in _allReminders) {
        String? assignedTo = reminder['assignedTo'];
        if (assignedTo != null && !_usersCache.containsKey(assignedTo)) {
          userIds.add(assignedTo);
        }
      }

      if (userIds.isEmpty) {
        _isFetchingUsers = false;
        return;
      }

      Map<String, Map<String, dynamic>> users = await _reminderService
          .getUsersBatch(userIds.toList());

      if (!_isDisposed) {
        _usersCache.addAll(users);
        _isFetchingUsers = false;
        notifyListeners();
      } else {
        _isFetchingUsers = false;
      }
    } catch (e) {
      _isFetchingUsers = false;
    }
  }

  /// Get elderly user name from cache
  String getElderlyName(String elderlyId) {
    Map<String, dynamic>? user = _usersCache[elderlyId];
    return _reminderService.formatUserDisplayName(user);
  }

  /// Get elderly user initials
  String getElderlyInitials(String elderlyId) {
    Map<String, dynamic>? user = _usersCache[elderlyId];
    return _reminderService.getUserInitials(user);
  }

  /// Get icon for reminder type
  IconData getReminderIcon(String reminderType) {
    String icon = _reminderService.getReminderTypeIcon(reminderType);
    switch (icon) {
      case '💊':
        return Icons.medication;
      case '📅':
        return Icons.calendar_today;
      case '🔔':
      default:
        return Icons.notifications;
    }
  }

  /// Get color for reminder type
  Color getReminderColor(String reminderType) {
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

  /// Format scheduled time for display
  String formatScheduledTime(Timestamp scheduledTime) {
    return _reminderService.formatReminderTime(scheduledTime);
  }

  /// Check if reminder is overdue
  bool isOverdue(Map<String, dynamic> reminder) {
    return _reminderService.isOverdue(reminder);
  }

  /// Check if reminder is completed
  bool isCompleted(Map<String, dynamic> reminder) {
    return reminder['isCompleted'] == true;
  }

  /// Get status tag for past reminders
  String getStatusTag(Map<String, dynamic> reminder) {
    if (isCompleted(reminder)) {
      return 'Completed';
    } else if (isOverdue(reminder)) {
      return 'Overdue';
    }
    return '';
  }

  /// Get status color for past reminders
  Color getStatusColor(Map<String, dynamic> reminder) {
    if (isCompleted(reminder)) {
      return Colors.green;
    } else if (isOverdue(reminder)) {
      return Colors.red;
    }
    return Colors.grey;
  }

  /// Mark reminder as complete (elderly only)
  Future<bool> markReminderComplete(String reminderId) async {
    if (_isDisposed || !isElderly) return false;

    try {
      await _reminderService.markReminderCompleteWithHistory(
        reminderId,
        _currentUserId,
      );
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        notifyListeners();
      }
      return false;
    }
  }

  /// Refresh reminders
  Future<void> refresh() async {
    if (_isDisposed) return;
    await loadRemindersForSelectedGroup();
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
    _remindersSubscription?.cancel();
    super.dispose();
  }
}
