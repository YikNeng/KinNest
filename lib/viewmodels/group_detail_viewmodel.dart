import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';
import '../services/reminder_service.dart';

class GroupDetailViewModel extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final ReminderService _reminderService = ReminderService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String groupId;

  // State variables
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _upcomingReminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get groupData => _groupData;
  List<Map<String, dynamic>> get upcomingReminders => _upcomingReminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _groupData != null;

  // Group info getters
  String get groupName => _groupData?['groupName'] ?? 'Unknown Group';
  String? get groupDescription => _groupData?['description'];
  List<Map<String, dynamic>> get members => _groupData?['members'] ?? [];
  List<Map<String, dynamic>> get pendingInvitations =>
      _groupService.getGroupInvitations(_groupData ?? {});

  // Permission checks
  bool get isAdmin => _groupService.isAdmin(_currentUserId, _groupData ?? {});
  bool get isMember => _groupService.isMember(_currentUserId, _groupData ?? {});

  GroupDetailViewModel({required this.groupId}) {
    initializeGroupStream();
  }

  /// Initialize group details stream (real-time updates)
  void initializeGroupStream() {
    _isLoading = true;
    notifyListeners();

    // Listen to group details
    _groupService
        .getGroupDetailsStream(groupId)
        .listen(
          (groupData) {
            if (groupData != null) {
              _groupData = groupData;
              _errorMessage = null;

              // Fetch reminders after group data is loaded
              _fetchReminders();
            } else {
              _errorMessage = 'Group not found';
              _isLoading = false;
            }
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load group: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Fetch upcoming reminders
  Future<void> _fetchReminders() async {
    try {
      _upcomingReminders = await _reminderService.getGroupUpcomingReminders(
        groupId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Don't fail the whole page if reminders fail to load
      _upcomingReminders = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      _groupData = await _groupService.getGroupDetails(groupId);
      _upcomingReminders = await _reminderService.getGroupUpcomingReminders(
        groupId,
      );
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh data';
      notifyListeners();
    }
  }

  /// Get member count (excluding admin)
  int get memberCount => members.length;

  /// Get member role label
  String getMemberRole(Map<String, dynamic> member) {
    if (member['isAdmin'] == true) {
      return 'Admin';
    }
    String role = member['role'] ?? 'member';
    return role.substring(0, 1).toUpperCase() + role.substring(1);
  }

  /// Get member role color
  Color getMemberRoleColor(Map<String, dynamic> member) {
    if (member['isAdmin'] == true) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  /// Format reminder time
  String formatReminderTime(Timestamp timestamp) {
    return _reminderService.formatReminderTime(timestamp);
  }

  /// Check if reminder is completed
  bool isReminderCompleted(Map<String, dynamic> reminder) {
    return reminder['isCompleted'] == true;
  }
}
