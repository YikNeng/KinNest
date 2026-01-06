import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';

class CreateGroupViewModel extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final String _adminId = FirebaseAuth.instance.currentUser!.uid;

  // Form controllers
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get adminId => _adminId;

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate all form fields
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

    // Validate description (optional)
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

  /// Create a new group
  /// Returns group ID on success, null on failure
  Future<String?> createGroup() async {
    // Clear previous errors
    _errorMessage = null;

    // Validate form
    if (!_validateForm()) {
      return null;
    }

    // Start loading
    _isLoading = true;
    notifyListeners();

    try {
      // Get form values
      String groupName = groupNameController.text.trim();
      String? description = descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim();

      // Call GroupService to create group
      String groupId = await _groupService.createGroup(
        groupName: groupName,
        adminId: _adminId,
        description: description,
      );

      // Creation successful
      _isLoading = false;
      notifyListeners();
      return groupId; // Return the created group's ID
    } catch (e) {
      // Creation failed
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear form fields
  void clearForm() {
    groupNameController.clear();
    descriptionController.clear();
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    groupNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
