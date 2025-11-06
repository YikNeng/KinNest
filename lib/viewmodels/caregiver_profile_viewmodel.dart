// lib/viewmodels/caregiver_profile_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';

class CaregiverProfileViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isEditMode = false;

  // Edit fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  // Password change fields
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Validation errors
  String? _usernameError;
  String? _emailError;
  String? _contactNumberError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  String? get usernameError => _usernameError;
  String? get emailError => _emailError;
  String? get contactNumberError => _contactNumberError;
  String? get currentPasswordError => _currentPasswordError;
  String? get newPasswordError => _newPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  CaregiverProfileViewModel() {
    _loadDummyUserProfile();
  }

  void _loadDummyUserProfile() {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with actual API call to fetch user profile
    Future.delayed(const Duration(milliseconds: 300), () {
      _currentUser = UserModel(
        id: 'caregiver_001',
        username: 'Aunty Mei',
        email: 'aunty.mei@example.com',
        hashedPassword: 'hashed_password_placeholder',
        age: 45,
        heightCm: 160.0,
        weightKg: 58.0,
        chronicDisease: false,
        chronicDiseaseNotes: '',
        avatarUrl: null,
        role: UserRole.caregiver,
        contactNumber: '+60123456789',
        assignedGroups: ['Family Care Group', 'Community Seniors'],
      );

      usernameController.text = _currentUser!.username;
      emailController.text = _currentUser!.email;
      contactNumberController.text = _currentUser!.contactNumber ?? '';

      _isLoading = false;
      notifyListeners();
    });
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (!_isEditMode) {
      // Cancel edit - reset fields
      if (_currentUser != null) {
        usernameController.text = _currentUser!.username;
        emailController.text = _currentUser!.email;
        contactNumberController.text = _currentUser!.contactNumber ?? '';
      }
      _clearValidationErrors();
    }
    notifyListeners();
  }

  bool _validateProfileFields() {
    bool isValid = true;
    _clearValidationErrors();

    // Validate username
    if (usernameController.text.trim().isEmpty) {
      _usernameError = 'Username cannot be empty';
      isValid = false;
    }

    // Validate email
    if (emailController.text.trim().isEmpty) {
      _emailError = 'Email cannot be empty';
      isValid = false;
    } else if (!emailController.text.contains('@')) {
      _emailError = 'Please enter a valid email';
      isValid = false;
    }

    // Validate contact number
    if (contactNumberController.text.trim().isNotEmpty) {
      if (contactNumberController.text.trim().length < 8) {
        _contactNumberError = 'Contact number must be at least 8 digits';
        isValid = false;
      }
    }

    notifyListeners();
    return isValid;
  }

  Future<bool> saveProfile() async {
    if (!_validateProfileFields()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // TODO: call backend API to update profile
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = _currentUser!.copyWith(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      contactNumber: contactNumberController.text.trim(),
    );

    _isEditMode = false;
    _isLoading = false;
    notifyListeners();

    return true;
  }

  bool _validatePasswordFields() {
    bool isValid = true;
    _clearPasswordErrors();

    // Validate current password
    if (currentPasswordController.text.isEmpty) {
      _currentPasswordError = 'Current password is required';
      isValid = false;
    }

    // Validate new password
    if (newPasswordController.text.isEmpty) {
      _newPasswordError = 'New password is required';
      isValid = false;
    } else if (newPasswordController.text.length < 6) {
      _newPasswordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    // Validate confirm password
    if (confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (newPasswordController.text != confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  Future<bool> changePassword() async {
    if (!_validatePasswordFields()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // TODO: hash password before sending to backend
    // Example: final hashedPassword = hashPassword(newPasswordController.text);

    // TODO: call backend API to change password
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = _currentUser!.copyWith(
      hashedPassword: 'new_hashed_password_placeholder',
    );

    _clearPasswordFields();
    _isLoading = false;
    notifyListeners();

    return true;
  }

  void _clearPasswordFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    _clearPasswordErrors();
  }

  void _clearPasswordErrors() {
    _currentPasswordError = null;
    _newPasswordError = null;
    _confirmPasswordError = null;
  }

  void _clearValidationErrors() {
    _usernameError = null;
    _emailError = null;
    _contactNumberError = null;
  }

  void logout() {
    // TODO: call backend API to logout and clear session
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
