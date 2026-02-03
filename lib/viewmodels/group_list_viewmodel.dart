import 'dart:async';
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

  // Stream subscription
  StreamSubscription<List<Map<String, dynamic>>>? _groupsSubscription;

  // Disposal tracking
  bool _isDisposed = false;

  // Getters
  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasGroups => _groups.isNotEmpty;
  String get userId => _userId;

  GroupListViewModel() {
    initializeGroupsStream();
  }

  /// Initialize and listen to groups stream
  void initializeGroupsStream() {
    _isLoading = true;
    _errorMessage = null;

    // Only notify if not disposed
    if (!_isDisposed) {
      notifyListeners();
    }

    // Cancel previous subscription if exists
    _groupsSubscription?.cancel();

    // Listen to real-time updates from Firestore
    _groupsSubscription = _groupService
        .getUserGroupsStream(_userId)
        .listen(
          (groupsList) {
            // Only update if not disposed
            if (!_isDisposed) {
              _groups = groupsList;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            }
          },
          onError: (error) {
            // Only update if not disposed
            if (!_isDisposed) {
              _errorMessage = 'Failed to load groups: $error';
              _isLoading = false;
              notifyListeners();
            }
          },
        );
  }

  /// Fetch groups
  Future<void> fetchGroups() async {
    if (_isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(_userId);

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

  /// Refresh groups
  Future<void> refreshGroups() async {
    if (_isDisposed) return;

    try {
      _groups = await _groupService.getUserGroups(_userId);

      if (!_isDisposed) {
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        notifyListeners();
      }
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

  /// Get role label
  String getRoleLabel(Map<String, dynamic> group) {
    return isAdmin(group) ? 'Admin' : 'Member';
  }

  /// Get role color
  Color getRoleColor(Map<String, dynamic> group) {
    return isAdmin(group) ? Colors.blue : Colors.grey;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _groupsSubscription?.cancel();
    super.dispose();
  }
}
