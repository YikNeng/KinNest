// lib/viewmodels/auth/register_elderly_viewmodel.dart

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class RegisterElderlyViewModel extends ChangeNotifier {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController chronicDiseaseNotesController =
      TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();

  bool _hasChronicDisease = false;
  bool _isLoading = false;
  String _groupOption = 'join'; // 'join' or 'create'

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _ageError;
  String? _heightError;
  String? _weightError;

  bool get hasChronicDisease => _hasChronicDisease;
  bool get isLoading => _isLoading;
  String get groupOption => _groupOption;
  String? get usernameError => _usernameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get ageError => _ageError;
  String? get heightError => _heightError;
  String? get weightError => _weightError;

  void setChronicDisease(bool value) {
    _hasChronicDisease = value;
    if (!value) {
      chronicDiseaseNotesController.clear();
    }
    notifyListeners();
  }

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

    if (ageController.text.trim().isEmpty) {
      _ageError = 'Age is required';
      isValid = false;
    } else {
      final age = int.tryParse(ageController.text);
      if (age == null || age <= 0) {
        _ageError = 'Please enter a valid age';
        isValid = false;
      }
    }

    if (heightController.text.trim().isEmpty) {
      _heightError = 'Height is required';
      isValid = false;
    } else {
      final height = double.tryParse(heightController.text);
      if (height == null || height <= 0) {
        _heightError = 'Please enter a valid height';
        isValid = false;
      }
    }

    if (weightController.text.trim().isEmpty) {
      _weightError = 'Weight is required';
      isValid = false;
    } else {
      final weight = double.tryParse(weightController.text);
      if (weight == null || weight <= 0) {
        _weightError = 'Please enter a valid weight';
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
    _ageError = null;
    _heightError = null;
    _weightError = null;
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
      age: int.parse(ageController.text),
      heightCm: double.parse(heightController.text),
      weightKg: double.parse(weightController.text),
      chronicDisease: _hasChronicDisease,
      chronicDiseaseNotes: chronicDiseaseNotesController.text.trim(),
      role: UserRole.elderly,
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
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    chronicDiseaseNotesController.dispose();
    inviteCodeController.dispose();
    groupNameController.dispose();
    super.dispose();
  }
}
