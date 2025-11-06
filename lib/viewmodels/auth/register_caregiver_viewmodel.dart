// lib/viewmodels/auth/register_caregiver_viewmodel.dart

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class RegisterCaregiverViewModel extends ChangeNotifier {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();

  bool _isLoading = false;
  String _groupOption = 'join'; // 'join' or 'create'

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _contactNumberError;

  bool get isLoading => _isLoading;
  String get groupOption => _groupOption;
  String? get usernameError => _usernameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get contactNumberError => _contactNumberError;

  void setGroupOption(String option) {
    _groupOption = option;
    notifyListeners();
  }

  bool _validateFields() {
    bool isValid = true;
    _clearErrors();

    if (usernameController.text.trim().isEmpty) {
      _usernameError = 'Username is required';
      isValid = false;
    }

    if (emailController.text.trim().isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!emailController.text.contains('@')) {
      _emailError = 'Please enter a valid email';
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (passwordController.text.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    if (confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (passwordController.text != confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    if (contactNumberController.text.trim().isNotEmpty) {
      if (contactNumberController.text.trim().length < 8) {
        _contactNumberError = 'Contact number must be at least 8 digits';
        isValid = false;
      }
    }

    notifyListeners();
    return isValid;
  }

  void _clearErrors() {
    _usernameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _contactNumberError = null;
  }

  Future<bool> register() async {
    if (!_validateFields()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // TODO: hash password before sending to backend
    // Example: final hashedPassword = hashPassword(passwordController.text);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Create user model
    final List<String> groups = [];
    if (_groupOption == 'create' &&
        groupNameController.text.trim().isNotEmpty) {
      groups.add(groupNameController.text.trim());
    } else if (_groupOption == 'join' &&
        inviteCodeController.text.trim().isNotEmpty) {
      // TODO: validate invite code and join group via backend
      groups.add('Joined Group'); // Placeholder
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      hashedPassword:
          'hashed_${passwordController.text}', // Placeholder for hashed password
      age: 0, // Not applicable for caregiver
      heightCm: 0.0,
      weightKg: 0.0,
      chronicDisease: false,
      chronicDiseaseNotes: '',
      role: UserRole.caregiver,
      contactNumber: contactNumberController.text.trim().isNotEmpty
          ? contactNumberController.text.trim()
          : null,
      assignedGroups: groups.isNotEmpty ? groups : null,
    );

    // TODO: Send user to backend API for registration
    // Store in-memory for prototype
    _registeredUsers.add(user);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // In-memory storage for prototype
  static final List<UserModel> _registeredUsers = [];

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    contactNumberController.dispose();
    inviteCodeController.dispose();
    groupNameController.dispose();
    super.dispose();
  }
}
