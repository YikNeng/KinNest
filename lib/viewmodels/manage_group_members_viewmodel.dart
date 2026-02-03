import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_member_model.dart';
import '../services/group_service.dart';

class ManageGroupMembersViewModel extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String groupId;

  // State
  List<GroupMemberModel> _members = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;
  bool _isDisposed = false;

  // Getters
  List<GroupMemberModel> get members => _members;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String? get errorMessage => _errorMessage;
  String get currentUserId => _currentUserId;

  // Get non-admin members only
  List<GroupMemberModel> get nonAdminMembers =>
      _members.where((m) => !m.isAdmin).toList();

  // Check if there are any non-admin members
  bool get hasNonAdminMembers => nonAdminMembers.isNotEmpty;

  ManageGroupMembersViewModel({required this.groupId}) {
    _initialize();
  }

  /// Initialize to check admin access and load members
  Future<void> _initialize() async {
    if (_isDisposed) return;

    await _checkAdminAccess();
    if (_isAdmin) {
      await loadMembers();
    } else {
      if (!_isDisposed) {
        _errorMessage = 'Access denied: Only group admins can manage members';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Check if current user is admin
  Future<void> _checkAdminAccess() async {
    if (_isDisposed) return;

    try {
      _isAdmin = await _groupService.isGroupAdmin(groupId, _currentUserId);
    } catch (e) {
      _isAdmin = false;
    }
  }

  /// Load all group members
  Future<void> loadMembers() async {
    if (_isDisposed) return;

    _isLoading = true;
    _errorMessage = null;

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      _members = await _groupService.getGroupMembers(groupId);

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

  /// Remove a member from the group
  Future<bool> removeMember(String userId) async {
    if (_isDisposed) return false;

    // Prevent admin from removing themselves
    if (userId == _currentUserId) {
      if (!_isDisposed) {
        _errorMessage = 'You cannot remove yourself from the group';
        notifyListeners();
      }
      return false;
    }

    try {
      await _groupService.removeMemberFromGroup(groupId, userId);

      // Reload members list
      await loadMembers();

      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        notifyListeners();
      }
      return false;
    }
  }

  /// Refresh members list
  Future<void> refresh() async {
    if (_isDisposed) return;
    await loadMembers();
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
