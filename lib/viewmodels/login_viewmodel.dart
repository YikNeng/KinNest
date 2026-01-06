import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate input fields
  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _errorMessage = 'Please enter your email';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Please enter your password';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Login method - returns true on success, false on failure
  Future<bool> login() async {
    // Clear previous errors
    _errorMessage = null;

    // Validate inputs
    if (!_validateInputs()) {
      return false;
    }

    // Start loading
    _isLoading = true;
    notifyListeners();

    try {
      // Call AuthService to login
      // Just login - GoRouter will handle redirect automatically
      await _authService.loginWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Login successful
      _isLoading = false;
      notifyListeners();
      return true; // GoRouter redirect will handle navigation
    } catch (e) {
      // Login failed
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
