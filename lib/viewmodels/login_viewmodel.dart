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
  bool _isDisposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  /// Toggle password visibility
  void togglePasswordVisibility() {
    if (_isDisposed) return;
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    if (_isDisposed) return;
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
    if (_isDisposed) return false;

    // Clear previous errors
    _errorMessage = null;

    // Validate inputs
    if (!_validateInputs()) {
      return false;
    }

    // Start loading
    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      // Call AuthService to login
      // Just login - GoRouter will handle redirect automatically
      await _authService.loginWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Login successful
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return true; // GoRouter redirect will handle navigation
    } catch (e) {
      // Login failed
      if (!_isDisposed) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
