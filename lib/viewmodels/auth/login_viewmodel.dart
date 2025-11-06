// lib/viewmodels/auth/login_viewmodel.dart

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.elderly;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _loginError;

  UserRole get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get loginError => _loginError;

  // Pre-seeded dummy users for testing
  final List<UserModel> _dummyUsers = [
    UserModel(
      id: 'elderly_dummy_1',
      username: 'Mr Lee',
      email: 'mr.lee@example.com',
      hashedPassword: 'hashed_password123', // Simulated hash of "password123"
      age: 72,
      heightCm: 168.0,
      weightKg: 65.0,
      chronicDisease: true,
      chronicDiseaseNotes: 'Hypertension',
      role: UserRole.elderly,
    ),
    UserModel(
      id: 'caregiver_dummy_1',
      username: 'Aunty Mei',
      email: 'aunty.mei@example.com',
      hashedPassword: 'hashed_password123', // Simulated hash of "password123"
      age: 45,
      heightCm: 160.0,
      weightKg: 58.0,
      chronicDisease: false,
      chronicDiseaseNotes: '',
      role: UserRole.caregiver,
      contactNumber: '+60123456789',
      assignedGroups: ['Family Care Group'],
    ),
  ];

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  bool _validateFields() {
    bool isValid = true;
    _clearErrors();

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
    }

    notifyListeners();
    return isValid;
  }

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _loginError = null;
  }

  Future<UserModel?> login() async {
    if (!_validateFields()) {
      return null;
    }

    _isLoading = true;
    _loginError = null;
    notifyListeners();

    // TODO: hash password before sending to backend for comparison
    // Example: final hashedPassword = hashPassword(passwordController.text);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Check against dummy users and registered users
    final allUsers = [..._dummyUsers];

    // Simple credential check
    // In real app: compare hashed passwords securely on backend
    final user = allUsers.firstWhere(
      (u) =>
          u.email == emailController.text.trim() &&
          u.hashedPassword == 'hashed_${passwordController.text}' &&
          u.role == _selectedRole,
      orElse: () => allUsers.firstWhere(
        (u) =>
            u.email == emailController.text.trim() &&
            u.hashedPassword == 'hashed_password123' && // Dummy user check
            passwordController.text == 'password123' &&
            u.role == _selectedRole,
        orElse: () => UserModel(
          id: '',
          username: '',
          email: '',
          hashedPassword: '',
          age: 0,
          heightCm: 0,
          weightKg: 0,
          chronicDisease: false,
          chronicDiseaseNotes: '',
          role: UserRole.elderly,
        ),
      ),
    );

    _isLoading = false;

    if (user.id.isEmpty) {
      _loginError = 'Invalid credentials';
      notifyListeners();
      return null;
    }

    notifyListeners();
    return user;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
