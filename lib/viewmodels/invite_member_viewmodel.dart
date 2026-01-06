import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/invitation_service.dart';
import '../services/group_service.dart';

class InviteMemberViewModel extends ChangeNotifier {
  final InvitationService _invitationService = InvitationService();
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final String groupId;

  // Form controllers
  final TextEditingController emailController = TextEditingController();

  // State variables
  String? _selectedRole; // "elderly" or "caregiver"
  bool _isLoading = false;
  bool _isCheckingPermission = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Role options
  final List<String> roles = ['Elderly', 'Caregiver'];

  // Getters
  String? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  bool get isCheckingPermission => _isCheckingPermission;
  bool get isAdmin => _isAdmin;
  String? get errorMessage => _errorMessage;

  InviteMemberViewModel({required this.groupId}) {
    _checkAdminPermission();
  }

  /// Check if current user is admin of this group
  Future<void> _checkAdminPermission() async {
    _isCheckingPermission = true;
    notifyListeners();

    try {
      _isAdmin = await _groupService.isUserGroupAdmin(_currentUserId, groupId);
      _isCheckingPermission = false;
      notifyListeners();
    } catch (e) {
      _isAdmin = false;
      _isCheckingPermission = false;
      _errorMessage = 'Failed to verify permissions';
      notifyListeners();
    }
  }

  /// Set selected role
  void setRole(String role) {
    _selectedRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate form
  bool _validateForm() {
    // Validate email
    String? emailError = _invitationService.validateEmail(emailController.text);
    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    // Validate role selection
    if (_selectedRole == null) {
      _errorMessage = 'Please select a role for the invitee';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Send invitation
  /// Returns true on success, false on failure
  Future<bool> sendInvitation() async {
    // Clear previous errors
    _errorMessage = null;

    // Validate form
    if (!_validateForm()) {
      return false;
    }

    // Check admin permission
    if (!_isAdmin) {
      _errorMessage = 'Only group admin can send invitations';
      notifyListeners();
      return false;
    }

    // Start loading
    _isLoading = true;
    notifyListeners();

    try {
      // Get form values
      String email = emailController.text.trim().toLowerCase();
      String role = _selectedRole!.toLowerCase(); // "elderly" or "caregiver"

      // Call InvitationService
      await _invitationService.sendInvitation(
        groupId: groupId,
        email: email,
        role: role,
        invitedBy: _currentUserId,
      );

      // Success
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Failed
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear form
  void clearForm() {
    emailController.clear();
    _selectedRole = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
