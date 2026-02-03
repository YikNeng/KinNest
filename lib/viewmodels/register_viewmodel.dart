import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Elderly-specific controllers
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController medicalConditionsController =
      TextEditingController();

  // State variables
  String? _selectedRole; // "elderly" or "caregiver"
  String? _selectedMobilityLevel; // "low", "medium", "high"
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isDisposed = false;

  // Mobility level options
  final List<String> mobilityLevels = ['Low', 'Medium', 'High'];

  // Getters
  String? get selectedRole => _selectedRole;
  String? get selectedMobilityLevel => _selectedMobilityLevel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get isElderlySelected => _selectedRole == 'elderly';

  /// Set user role
  void setRole(String role) {
    _selectedRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set mobility level (for elderly only)
  void setMobilityLevel(String? level) {
    _selectedMobilityLevel = level;
    notifyListeners();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate all input fields
  bool _validateInputs() {
    // Check role selection
    if (_selectedRole == null) {
      _errorMessage = 'Please select your role';
      notifyListeners();
      return false;
    }

    // Validate name
    if (nameController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your name';
      notifyListeners();
      return false;
    }

    // Validate email
    final email = emailController.text.trim();
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

    // Validate password
    final password = passwordController.text;
    if (password.isEmpty) {
      _errorMessage = 'Please enter a password';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    // Validate confirm password
    if (confirmPasswordController.text != password) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    // Validate elderly-specific fields
    if (_selectedRole == 'elderly') {
      if (ageController.text.trim().isEmpty) {
        _errorMessage = 'Please enter your age';
        notifyListeners();
        return false;
      }

      final age = int.tryParse(ageController.text.trim());
      if (age == null || age < 1 || age > 120) {
        _errorMessage = 'Please enter a valid age (1-120)';
        notifyListeners();
        return false;
      }

      if (heightController.text.trim().isEmpty) {
        _errorMessage = 'Please enter your height';
        notifyListeners();
        return false;
      }

      final height = double.tryParse(heightController.text.trim());
      if (height == null || height < 50 || height > 250) {
        _errorMessage = 'Please enter a valid height (50-250 cm)';
        notifyListeners();
        return false;
      }

      if (weightController.text.trim().isEmpty) {
        _errorMessage = 'Please enter your weight';
        notifyListeners();
        return false;
      }

      final weight = double.tryParse(weightController.text.trim());
      if (weight == null || weight < 20 || weight > 300) {
        _errorMessage = 'Please enter a valid weight (20-300 kg)';
        notifyListeners();
        return false;
      }

      if (_selectedMobilityLevel == null) {
        _errorMessage = 'Please select your mobility level';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Register new user
  Future<bool> register() async {
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
      // Create user in Firebase Auth
      String uid = await _authService.registerWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Create user profile in Firestore
      String? phone = phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim();

      if (_selectedRole == 'elderly') {
        await _userService.createUserProfile(
          uid: uid,
          email: emailController.text.trim(),
          name: nameController.text.trim(),
          role: 'elderly',
          phone: phone,
          age: int.parse(ageController.text.trim()),
          height: double.parse(heightController.text.trim()),
          weight: double.parse(weightController.text.trim()),
          medicalConditions: medicalConditionsController.text.trim().isEmpty
              ? null
              : medicalConditionsController.text.trim(),
          mobilityLevel: _selectedMobilityLevel?.toLowerCase(),
        );
      } else {
        await _userService.createUserProfile(
          uid: uid,
          email: emailController.text.trim(),
          name: nameController.text.trim(),
          role: 'caregiver',
          phone: phone,
        );
      }

      // Registration successful
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      // Registration failed
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    medicalConditionsController.dispose();
    super.dispose();
  }
}
