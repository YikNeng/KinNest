import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class CaregiverProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userGroups = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  Map<String, dynamic>? get userData => _userData;
  List<Map<String, dynamic>> get userGroups => _userGroups;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get userName => _userData?['name'] ?? 'Unknown';
  String get userEmail => _userData?['email'] ?? '';
  String get userRole => _userData?['role'] ?? 'caregiver';
  int get groupCount => _userGroups.length;
  int get adminGroupCount =>
      _userGroups.where((g) => g['role'] == 'Admin').length;
  String get userPhoneNumber => _userData?['phoneNumber'] ?? '';
  bool get hasPhoneNumber => userPhoneNumber.isNotEmpty;

  CaregiverProfileViewModel() {
    _initialize();
  }

  /// Update user phone number
  Future<bool> updateUserPhoneNumber({
    required String userId,
    required String phoneNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'phoneNumber': phoneNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update phone number: $e');
    }
  }

  /// Validate Malaysia phone number
  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Remove spaces, dashes and parentheses
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+60')) {
      String withoutCode = cleaned.substring(3);
      if (!RegExp(r'^\d{9,11}$').hasMatch(withoutCode)) {
        return 'Invalid Malaysian phone number format';
      }
      if (!withoutCode.startsWith('1')) {
        return 'Malaysian mobile numbers must start with 01';
      }
    } else if (cleaned.startsWith('60')) {
      String withoutCode = cleaned.substring(2);
      if (!RegExp(r'^\d{9,11}$').hasMatch(withoutCode)) {
        return 'Invalid Malaysian phone number format';
      }
      if (!withoutCode.startsWith('1')) {
        return 'Malaysian mobile numbers must start with 01';
      }
    } else if (cleaned.startsWith('0')) {
      if (!RegExp(r'^0\d{9,10}$').hasMatch(cleaned)) {
        return 'Phone number must be 10-11 digits';
      }
      if (!cleaned.startsWith('01')) {
        return 'Malaysian mobile numbers must start with 01';
      }
    } else {
      return 'Please enter a valid Malaysian phone number';
    }

    return null;
  }

  /// Format Malaysia phone number for display
  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;

    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d\+]'), '');

    if (cleaned.isEmpty) return phoneNumber;

    if (cleaned.startsWith('+60')) {
      String withoutCode = cleaned.substring(3);
      if (withoutCode.length >= 9) {
        String prefix = withoutCode.substring(0, 2);
        String middle = withoutCode.substring(2, withoutCode.length - 4);
        String last = withoutCode.substring(withoutCode.length - 4);
        return '+60 $prefix-$middle $last';
      }
      return cleaned;
    } else if (cleaned.startsWith('60')) {
      String withoutCode = cleaned.substring(2);
      if (withoutCode.length >= 9) {
        String prefix = withoutCode.substring(0, 2);
        String middle = withoutCode.substring(2, withoutCode.length - 4);
        String last = withoutCode.substring(withoutCode.length - 4);
        return '+60 $prefix-$middle $last';
      }
      return '+' + cleaned;
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length == 10) {
        return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
      } else if (cleaned.length == 11) {
        return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)} ${cleaned.substring(7)}';
      }
      return cleaned;
    }

    return phoneNumber;
  }

  /// Get Malaysia phone number examples
  String getPhoneNumberHint() {
    return '010-123 4567 or +60 10-123 4567';
  }

  /// Get Malaysia phone number help text
  String getPhoneNumberHelpText() {
    return 'Malaysian format:\n'
        '• Local: 01X-XXXX XXXX\n'
        '• International: +60 1X-XXXX XXXX';
  }

  /// Initialize to fetch user data and groups
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user details
      _userData = await _profileService.getCurrentUserDetails();

      if (_userData == null) {
        _errorMessage = 'User not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user groups with roles
      _userGroups = await _profileService.getUserGroupsWithRoles(
        _currentUserId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await _initialize();
  }

  /// Update profile name
  Future<bool> updateProfileName(String newName) async {
    _errorMessage = null;
    _successMessage = null;

    // Validate name
    String? validationError = _profileService.validateName(newName);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isUpdating = true;
    notifyListeners();

    try {
      await _profileService.updateUserProfile(
        userId: _currentUserId,
        name: newName,
      );

      // Update local data
      _userData?['name'] = newName;
      _successMessage = 'Profile updated successfully';
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Update email
  Future<bool> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    // Validate email
    String? emailError = _profileService.validateEmail(newEmail);
    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    // Validate password
    String? passwordError = _profileService.validatePassword(currentPassword);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    _isUpdating = true;
    notifyListeners();

    try {
      await _profileService.updateUserEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );

      // Update local data
      _userData?['email'] = newEmail;
      _successMessage = 'Email updated Successfully!';
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    // Validate current password
    String? currentPasswordError = _profileService.validatePassword(
      currentPassword,
    );
    if (currentPasswordError != null) {
      _errorMessage = currentPasswordError;
      notifyListeners();
      return false;
    }

    // Validate new password
    String? newPasswordError = _profileService.validatePassword(newPassword);
    if (newPasswordError != null) {
      _errorMessage = newPasswordError;
      notifyListeners();
      return false;
    }

    // Check if passwords match
    if (newPassword != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    // Check if new password is different
    if (currentPassword == newPassword) {
      _errorMessage = 'New password must be different from current password';
      notifyListeners();
      return false;
    }

    _isUpdating = true;
    notifyListeners();

    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _successMessage = 'Password changed successfully';
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      await _profileService.signOut();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Get role badge color
  Color getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
