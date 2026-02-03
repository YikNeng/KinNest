import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';
import '../services/alarm_service.dart';

class ReminderViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final AlarmService _alarmService = AlarmService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Stream subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _remindersSubscription;
  StreamSubscription<QuerySnapshot>? _historySubscription;

  // Disposal tracking
  bool _isDisposed = false;

  // State
  String? _userRole;
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _allReminders = [];
  Map<String, Map<String, dynamic>> _usersCache = {};
  String _filterMode = 'upcoming';

  bool _isLoading = false;
  bool _isFetchingUsers = false;
  String? _errorMessage;

  // Counters
  int _pastCount = 0;

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

  Future<void> _initialize() async {
    if (_isDisposed) return;
    await _detectUserRole();
    await loadGroups();
  }

  Future<void> _detectUserRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists && !_isDisposed) {
        _userRole = (userDoc.data() as Map<String, dynamic>)['role'];
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> loadGroups() async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isCaregiver) {
        await _loadCaregiverGroups();
      } else if (isElderly) {
        await _loadElderlyGroups();
      }

      if (!_isDisposed && _groups.isNotEmpty) {
        _selectedGroup = _groups.first;
        _subscribeToReminders();
        _subscribeToHistory();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadCaregiverGroups() async {
    var snap = await FirebaseFirestore.instance
        .collection('groups')
        .where('adminId', isEqualTo: _currentUserId)
        .get();
    if (!_isDisposed) {
      _groups = snap.docs.map((d) {
        var data = d.data();
        data['groupId'] = d.id;
        return data;
      }).toList();
    }
  }

  Future<void> _loadElderlyGroups() async {
    var snap = await FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: _currentUserId)
        .get();
    if (!_isDisposed) {
      _groups = snap.docs.map((d) {
        var data = d.data();
        data['groupId'] = d.id;
        return data;
      }).toList();
    }
  }

  void selectGroup(Map<String, dynamic> group) {
    if (_isDisposed || _selectedGroup?['groupId'] == group['groupId']) return;
    _selectedGroup = group;
    _allReminders = [];
    notifyListeners();
    _subscribeToReminders();
    _subscribeToHistory();
  }

  void _subscribeToReminders() {
    if (_selectedGroup == null) return;
    _remindersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _remindersSubscription = _reminderService
        .getGroupRemindersStream(_selectedGroup!['groupId'])
        .listen(
          (data) {
            if (_isDisposed) return;
            _allReminders = data;
            _reminderService.processMissedReminders(_allReminders);

            _isLoading = false;
            _fetchAssignedUsers();
            notifyListeners();
          },
          onError: (e) {
            if (!_isDisposed) {
              _isLoading = false;
              notifyListeners();
            }
          },
        );
  }

  void _subscribeToHistory() {
    _historySubscription?.cancel();

    // Don't subscribe if no group is selected
    if (_selectedGroup == null || _selectedGroup!['groupId'] == null) return;

    _historySubscription = FirebaseFirestore.instance
        .collection('reminder_history')
        .where('groupId', isEqualTo: _selectedGroup!['groupId'])
        .where('status', whereIn: ['completed', 'overdue'])
        .snapshots()
        .listen((snapshot) {
          if (_isDisposed) return;
          _pastCount = snapshot.docs.length;
          notifyListeners();
        });
  }

  List<Map<String, dynamic>> _getFilteredReminders() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filtered;

    if (_filterMode == 'upcoming') {
      filtered =
          _allReminders.where((r) {
            if (r['isCompleted'] == true) return false;

            Timestamp ts = r['scheduledTime'];
            return ts.toDate().add(const Duration(minutes: 2)).isAfter(now);
          }).toList()..sort(
            (a, b) =>
                (a['scheduledTime'] as Timestamp).compareTo(b['scheduledTime']),
          );
    } else {
      filtered =
          _allReminders.where((r) {
            if (r['isCompleted'] == true) return false;

            Timestamp ts = r['scheduledTime'];
            // Move to 'Past' only after the 2-minute buffer has passed
            return ts.toDate().add(const Duration(minutes: 2)).isBefore(now);
          }).toList()..sort(
            (a, b) =>
                (b['scheduledTime'] as Timestamp).compareTo(a['scheduledTime']),
          );
    }

    if (isElderly) {
      filtered = filtered
          .where((r) => r['assignedTo'] == _currentUserId)
          .toList();
    }
    return filtered;
  }

  void setFilterMode(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  int get upcomingCount {
    DateTime now = DateTime.now();
    var list = _allReminders.where((r) {
      Timestamp ts = r['scheduledTime'];
      return (ts.toDate().add(const Duration(minutes: 2)).isAfter(now)) &&
          r['isCompleted'] != true;
    });
    if (isElderly) list = list.where((r) => r['assignedTo'] == _currentUserId);
    return list.length;
  }

  int get pastCount {
    DateTime now = DateTime.now();
    // Calculate Active Overdue Count (Incomplete items past the buffer)
    int activeOverdueCount = _allReminders.where((r) {
      Timestamp ts = r['scheduledTime'];

      // Only count as overdue if 2 minutes have passed
      bool isOverdue = ts
          .toDate()
          .add(const Duration(minutes: 2))
          .isBefore(now);
      bool isIncomplete = r['isCompleted'] != true;

      bool isUserBound = isElderly ? r['assignedTo'] == _currentUserId : true;

      return isOverdue && isIncomplete && isUserBound;
    }).length;

    // Return combined count (Firestore History + Active Overdue)
    return _pastCount + activeOverdueCount;
  }

  Future<bool> markReminderComplete(String reminderId) async {
    if (_isDisposed || !isElderly) return false;
    try {
      final reminder = _allReminders.firstWhere(
        (r) => r['reminderId'] == reminderId,
        orElse: () => {},
      );

      if (reminder.isEmpty) return false;

      String groupId = reminder['groupId'];
      String title = reminder['title'] ?? 'Untitled';
      DateTime currentDueDate = (reminder['scheduledTime'] as Timestamp)
          .toDate();
      String repeatInterval = reminder['repeatType'] ?? 'daily';

      List<dynamic>? rawDays = reminder['repeatDays'];
      List<int>? repeatDays = rawDays != null ? List<int>.from(rawDays) : null;

      await _reminderService.completeRecurringTask(
        reminderId: reminderId,
        title: title,
        groupId: groupId,
        currentDueDate: currentDueDate,
        repeatInterval: repeatInterval,
        repeatDays: repeatDays,
      );

      await _alarmService.cancelReminderAlarm(reminderId);

      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString();
        notifyListeners();
      }
      return false;
    }
  }

  // Helpers
  Future<void> _fetchAssignedUsers() async {
    if (_isDisposed || _isFetchingUsers) return;
    _isFetchingUsers = true;
    try {
      Set<String> ids = _allReminders
          .map((r) => r['assignedTo'] as String)
          .toSet();
      if (ids.isEmpty) {
        _isFetchingUsers = false;
        return;
      }
      var users = await _reminderService.getUsersBatch(ids.toList());
      if (!_isDisposed) {
        _usersCache.addAll(users);
        _isFetchingUsers = false;
        notifyListeners();
      }
    } catch (_) {
      _isFetchingUsers = false;
    }
  }

  String getElderlyName(String id) =>
      _reminderService.formatUserDisplayName(_usersCache[id]);

  IconData getReminderIcon(String type) =>
      _reminderService.getReminderTypeIcon(type) == '💊'
      ? Icons.medication_liquid
      : (_reminderService.getReminderTypeIcon(type) == '📅'
            ? Icons.calendar_month
            : Icons.notifications_active);

  Color getReminderColor(String type) =>
      _reminderService.getReminderTypeColorName(type) == 'red'
      ? Colors.red
      : (_reminderService.getReminderTypeColorName(type) == 'blue'
            ? Colors.blue
            : (_reminderService.getReminderTypeColorName(type) == 'green'
                  ? Colors.green
                  : Colors.orange));

  String formatScheduledTime(Timestamp ts) =>
      _reminderService.formatReminderTime(ts);

  bool isCompleted(Map<String, dynamic> r) => r['isCompleted'] == true;

  String getStatusTag(Map<String, dynamic> reminder) {
    if (reminder['isCompleted'] == true) {
      return 'Completed';
    }
    return 'Overdue';
  }

  Color getStatusColor(Map<String, dynamic> reminder) {
    if (reminder['isCompleted'] == true) {
      return Colors.green;
    }
    return Colors.red;
  }

  Future<void> refresh() async {
    _subscribeToReminders();
    _subscribeToHistory();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _remindersSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
