import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ElderlyProfileViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isEditingHealthInfo = false;

  // Password requirements
  static const int minPasswordLength = 8;
  static const String passwordRequirements =
      'Password must be at least 8 characters and contain:\n'
      '• At least one uppercase letter (A-Z)\n'
      '• At least one lowercase letter (a-z)\n'
      '• At least one number (0-9)\n'
      '• At least one special character (!@#\$%^&*)';

  // Form controllers for health info
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController chronicDiseaseNotesController =
      TextEditingController();

  // Password change controllers
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Validation errors
  String? _emailError;
  String? _ageError;
  String? _heightError;
  String? _weightError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isEditingHealthInfo => _isEditingHealthInfo;
  String? get emailError => _emailError;
  String? get ageError => _ageError;
  String? get heightError => _heightError;
  String? get weightError => _weightError;
  String? get currentPasswordError => _currentPasswordError;
  String? get newPasswordError => _newPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  ElderlyProfileViewModel() {
    _loadDummyUserData();
  }

  void _loadDummyUserData() {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with actual API call to fetch user data
    Future.delayed(const Duration(milliseconds: 500), () {
      _currentUser = UserModel(
        id: 'user_001',
        username: 'John Anderson',
        email: 'john.anderson@email.com',
        hashedPassword: 'hashed_password_12345', // Simulated hashed password
        age: 68,
        heightCm: 165.0,
        weightKg: 70.0,
        chronicDisease: true,
        chronicDiseaseNotes: 'Diabetes Type 2, Hypertension',
        avatarUrl: null,
      );

      _populateHealthInfoControllers();
      _isLoading = false;
      notifyListeners();
    });
  }

  void _populateHealthInfoControllers() {
    if (_currentUser != null) {
      ageController.text = _currentUser!.age.toString();
      heightController.text = _currentUser!.heightCm.toString();
      weightController.text = _currentUser!.weightKg.toString();
      chronicDiseaseNotesController.text = _currentUser!.chronicDiseaseNotes;
    }
  }

  void toggleEditHealthInfo() {
    _isEditingHealthInfo = !_isEditingHealthInfo;
    if (!_isEditingHealthInfo) {
      // Reset controllers if canceling edit
      _populateHealthInfoControllers();
      _clearHealthInfoErrors();
    }
    notifyListeners();
  }

  void toggleChronicDisease(bool value) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(chronicDisease: value);
      if (!value) {
        _currentUser = _currentUser!.copyWith(chronicDiseaseNotes: '');
        chronicDiseaseNotesController.clear();
      }
      notifyListeners();
    }
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (email.isEmpty) {
      _emailError = 'Email is required';
      return false;
    }
    if (!emailRegex.hasMatch(email)) {
      _emailError = 'Please enter a valid email';
      return false;
    }
    _emailError = null;
    return true;
  }

  bool _validateHealthInfo() {
    bool isValid = true;

    // Validate age
    final age = int.tryParse(ageController.text);
    if (age == null || age <= 0) {
      _ageError = 'Please enter a valid age';
      isValid = false;
    } else {
      _ageError = null;
    }

    // Validate height
    final height = double.tryParse(heightController.text);
    if (height == null || height <= 0) {
      _heightError = 'Please enter a valid height';
      isValid = false;
    } else {
      _heightError = null;
    }

    // Validate weight
    final weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0) {
      _weightError = 'Please enter a valid weight';
      isValid = false;
    } else {
      _weightError = null;
    }

    notifyListeners();
    return isValid;
  }

  void _clearHealthInfoErrors() {
    _ageError = null;
    _heightError = null;
    _weightError = null;
    notifyListeners();
  }

  // TODO: call backend API to update health info
  Future<bool> saveHealthInfo() async {
    if (!_validateHealthInfo()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = _currentUser!.copyWith(
      age: int.parse(ageController.text),
      heightCm: double.parse(heightController.text),
      weightKg: double.parse(weightController.text),
      chronicDiseaseNotes: chronicDiseaseNotesController.text,
    );

    _isEditingHealthInfo = false;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  bool _validatePasswordChange() {
    bool isValid = true;

    // Validate current password
    if (currentPasswordController.text.isEmpty) {
      _currentPasswordError = 'Current password is required';
      isValid = false;
    } else {
      _currentPasswordError = null;
    }

    // Validate new password
    final newPassword = newPasswordController.text;
    if (newPassword.isEmpty) {
      _newPasswordError = 'New password is required';
      isValid = false;
    } else if (newPassword.length < minPasswordLength) {
      _newPasswordError =
          'Password must be at least $minPasswordLength characters';
      isValid = false;
    } else if (!_hasUppercase(newPassword)) {
      _newPasswordError = 'Password must contain at least one uppercase letter';
      isValid = false;
    } else if (!_hasLowercase(newPassword)) {
      _newPasswordError = 'Password must contain at least one lowercase letter';
      isValid = false;
    } else if (!_hasDigit(newPassword)) {
      _newPasswordError = 'Password must contain at least one number';
      isValid = false;
    } else if (!_hasSpecialChar(newPassword)) {
      _newPasswordError =
          'Password must contain at least one special character (!@#\$%^&*)';
      isValid = false;
    } else {
      _newPasswordError = null;
    }

    // Validate confirm password
    if (confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (newPasswordController.text != confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    } else {
      _confirmPasswordError = null;
    }

    notifyListeners();
    return isValid;
  }

  bool _hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  bool _hasLowercase(String password) {
    return password.contains(RegExp(r'[a-z]'));
  }

  bool _hasDigit(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  bool _hasSpecialChar(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void clearPasswordErrors() {
    _currentPasswordError = null;
    _newPasswordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  void clearPasswordFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    clearPasswordErrors();
  }

  // TODO: hash password before sending to backend
  // TODO: call backend API to change password
  Future<bool> changePassword() async {
    if (!_validatePasswordChange()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate password hashing
    // In production: use crypto library like bcrypt or argon2
    // Example: final hashedPassword = hashPassword(newPasswordController.text);
    final simulatedHashedPassword =
        'hashed_${newPasswordController.text}_${DateTime.now().millisecondsSinceEpoch}';

    _currentUser =
        _currentUser!.copyWith(hashedPassword: simulatedHashedPassword);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // TODO: call backend API to logout and clear session
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Simulate logout API call
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    chronicDiseaseNotesController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
