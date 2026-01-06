import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';

class GroupListViewModel extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // State variables
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasGroups => _groups.isNotEmpty;
  String get userId => _userId;

  /// Initialize and listen to groups stream
  void initializeGroupsStream() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Listen to real-time updates from Firestore
    _groupService
        .getUserGroupsStream(_userId)
        .listen(
          (groupsList) {
            _groups = groupsList;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load groups: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Fetch groups (one-time fetch, alternative to stream)
  Future<void> fetchGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh groups (pull-to-refresh)
  Future<void> refreshGroups() async {
    try {
      _groups = await _groupService.getUserGroups(_userId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Check if user is admin of a group
  bool isAdmin(Map<String, dynamic> group) {
    return _groupService.isAdmin(_userId, group);
  }

  /// Get member count for a group
  int getMemberCount(Map<String, dynamic> group) {
    return _groupService.getMemberCount(group);
  }

  /// Get role label (Admin or Member)
  String getRoleLabel(Map<String, dynamic> group) {
    return isAdmin(group) ? 'Admin' : 'Member';
  }

  /// Get role color
  Color getRoleColor(Map<String, dynamic> group) {
    return isAdmin(group) ? Colors.blue : Colors.grey;
  }
}
