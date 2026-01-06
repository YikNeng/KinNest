import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';

class GroupSettingsViewModel extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String groupId;

  // Form controllers
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // State variables
  Map<String, dynamic>? _groupData;
  bool _isLoading = false;
  bool _isFetchingData = true;
  bool _isDeleting = false;
  String? _errorMessage;
  int _memberCount = 0;
  int _reminderCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isFetchingData => _isFetchingData;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _groupData?['adminId'] == _currentUserId;
  int get memberCount => _memberCount;
  int get reminderCount => _reminderCount;
  String get groupName => _groupData?['groupName'] ?? 'Unknown Group';

  GroupSettingsViewModel({required this.groupId}) {
    _initialize();
  }

  /// Initialize - fetch group data
  Future<void> _initialize() async {
    _isFetchingData = true;
    notifyListeners();

    try {
      // Fetch group details
      _groupData = await _groupService.getGroupDetails(groupId);

      if (_groupData == null) {
        _errorMessage = 'Group not found';
        _isFetchingData = false;
        notifyListeners();
        return;
      }

      // Check admin permission
      if (!isAdmin) {
        _errorMessage = 'Only group admin can access settings';
        _isFetchingData = false;
        notifyListeners();
        return;
      }

      // Populate form
      groupNameController.text = _groupData!['groupName'] ?? '';
      descriptionController.text = _groupData!['description'] ?? '';

      // Fetch counts
      _memberCount = await _groupService.getGroupMemberCount(groupId);
      _reminderCount = await _groupService.getGroupReminderCount(groupId);

      _isFetchingData = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load group data: $e';
      _isFetchingData = false;
      notifyListeners();
    }
  }

  /// Validate form
  bool _validateForm() {
    // Validate group name
    String? nameError = _groupService.validateGroupName(
      groupNameController.text,
    );
    if (nameError != null) {
      _errorMessage = nameError;
      notifyListeners();
      return false;
    }

    // Validate description
    String? descError = _groupService.validateGroupDescription(
      descriptionController.text,
    );
    if (descError != null) {
      _errorMessage = descError;
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Save group changes
  Future<bool> saveChanges() async {
    _errorMessage = null;

    // Validate form
    if (!_validateForm()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _groupService.updateGroup(
        groupId: groupId,
        groupName: groupNameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete group
  Future<bool> deleteGroup() async {
    if (!isAdmin) {
      _errorMessage = 'Only group admin can delete the group';
      notifyListeners();
      return false;
    }

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groupService.deleteGroup(groupId);
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if form has changes
  bool hasChanges() {
    if (_groupData == null) return false;

    String originalName = _groupData!['groupName'] ?? '';
    String originalDesc = _groupData!['description'] ?? '';
    String currentName = groupNameController.text.trim();
    String currentDesc = descriptionController.text.trim();

    return originalName != currentName || originalDesc != currentDesc;
  }

  @override
  void dispose() {
    groupNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
