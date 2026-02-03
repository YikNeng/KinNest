import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/alarm_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AlarmService _alarmService = AlarmService();

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

  /// Login method
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
      // Attempt Login with Auto-Retry Logic
      try {
        await _authService.loginWithEmailPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } catch (e) {
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('user account is missing') ||
            errorString.contains('unavailable')) {
          debugPrint(
            '⚠️ Connection issue or Cold start detected. Retrying login...',
          );

          await Future.delayed(const Duration(milliseconds: 1500));

          if (_isDisposed) return false;

          // Retry the login
          await _authService.loginWithEmailPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
        } else {
          rethrow;
        }
      }

      // Post-Login Logic (Schedule Alarms)

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Login succeeded but user is null');
      }

      String userId = user.uid;

      // Get user role to check if elderly
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? '';

        // Only schedule alarms for elderly users
        if (role == 'elderly') {
          await _alarmService.scheduleAllUserReminders(userId);
        }
      }

      // Login successful
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return true;
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
