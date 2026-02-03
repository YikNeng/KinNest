import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/elderly_profile_model.dart';
import '../services/user_service.dart';

class ElderlyProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // State
  ElderlyProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Form controllers for editable fields
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController medicalConditionController =
      TextEditingController();

  // Dropdown for mobility level
  String? _selectedMobilityLevel;

  // Getters
  ElderlyProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get selectedMobilityLevel => _selectedMobilityLevel;

  // User data getters
  String get userName => _profile?.name ?? 'Unknown';

  String get userEmail => _profile?.email ?? '';

  // Available mobility levels
  final List<String> mobilityLevels = [
    'Normal mobility',
    'Limited mobility',
    'Uses walking aid',
    'Wheelchair user',
  ];

  // Map old values to new values
  String _normalizeMobilityLevel(String? oldValue) {
    if (oldValue == null || oldValue.isEmpty) {
      return mobilityLevels[0];
    }

    // Mapping for backward compatibility
    final Map<String, String> legacyMapping = {
      'low': 'Limited mobility',
      'medium': 'Normal mobility',
      'high': 'Normal mobility',
      'normal': 'Normal mobility',
      'limited': 'Limited mobility',
    };

    String normalizedValue = oldValue.toLowerCase().trim();

    // Check if it's a legacy value
    if (legacyMapping.containsKey(normalizedValue)) {
      return legacyMapping[normalizedValue]!;
    }

    // Check if it already matches one of our standard values
    for (String level in mobilityLevels) {
      if (level.toLowerCase() == normalizedValue) {
        return level;
      }
    }

    // Default fallback
    return mobilityLevels[0];
  }

  ElderlyProfileViewModel() {
    _initialize();
  }

  /// Initialize to load profile
  Future<void> _initialize() async {
    await loadProfile();
  }

  /// Load profile from Firestore
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userService.getCurrentUserProfile();

      if (_profile == null) {
        _errorMessage = 'Profile not found';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh profile
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Pre-fill form for editing
  void prepareForEdit() {
    if (_profile == null) return;

    ageController.text = _profile!.age?.toString() ?? '';
    heightController.text = _profile!.height?.toString() ?? '';
    weightController.text = _profile!.weight?.toString() ?? '';
    medicalConditionController.text = _profile!.medicalConditions ?? '';

    // Normalize the mobility level from database
    _selectedMobilityLevel = _normalizeMobilityLevel(_profile!.mobilityLevel);

    notifyListeners();
  }

  /// Set mobility level
  void setMobilityLevel(String? value) {
    _selectedMobilityLevel = value;
    notifyListeners();
  }

  /// Validate form inputs
  bool _validateInputs() {
    // Age validation
    if (ageController.text.isNotEmpty) {
      int? age = int.tryParse(ageController.text);
      if (age == null || age < 50 || age > 120) {
        _errorMessage = 'Please enter a valid age (50-120)';
        notifyListeners();
        return false;
      }
    }

    // Height validation
    if (heightController.text.isNotEmpty) {
      double? height = double.tryParse(heightController.text);
      if (height == null || height < 100 || height > 250) {
        _errorMessage = 'Please enter a valid height (100-250 cm)';
        notifyListeners();
        return false;
      }
    }

    // Weight validation
    if (weightController.text.isNotEmpty) {
      double? weight = double.tryParse(weightController.text);
      if (weight == null || weight < 30 || weight > 200) {
        _errorMessage = 'Please enter a valid weight (30-200 kg)';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  /// Save profile changes
  Future<bool> saveProfile() async {
    _errorMessage = null;
    _successMessage = null;

    if (!_validateInputs()) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      int? age = ageController.text.isNotEmpty
          ? int.tryParse(ageController.text)
          : null;

      double? height = heightController.text.isNotEmpty
          ? double.tryParse(heightController.text)
          : null;

      double? weight = weightController.text.isNotEmpty
          ? double.tryParse(weightController.text)
          : null;

      String? medicalConditions = medicalConditionController.text.isNotEmpty
          ? medicalConditionController.text.trim()
          : "None";

      await _userService.updateElderlyProfile(
        userId: _currentUserId,
        age: age,
        height: height,
        weight: weight,
        medicalConditions: medicalConditions,
        mobilityLevel: _selectedMobilityLevel,
      );

      await loadProfile();

      _successMessage = 'Profile updated successfully!';
      _isSaving = false;
      _clearControllers();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          'Failed to save profile: ${e.toString().replaceAll('Exception: ', '')}';
      _isSaving = false;
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

    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'All password fields are required';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _errorMessage = 'New password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _errorMessage = 'New passwords do not match';
      notifyListeners();
      return false;
    }

    if (currentPassword == newPassword) {
      _errorMessage = 'New password must be different from current password';
      notifyListeners();
      return false;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      _successMessage = 'Password changed successfully!';
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'New password is too weak';
      } else {
        _errorMessage = 'Failed to change password: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to change password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Change email
  Future<bool> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    // Validation
    if (newEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Email and password are required';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(newEmail)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    if (newEmail == userEmail) {
      _errorMessage = 'New email must be different from current email';
      notifyListeners();
      return false;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Update email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore
      await _userService.updateUserEmail(_currentUserId, newEmail);

      // Reload profile
      await loadProfile();

      _successMessage = 'Email updated successfully!';
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'This email is already in use';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Password is incorrect';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Invalid email address';
      } else {
        _errorMessage = 'Failed to change email: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to change email: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Clear all form controllers
  void _clearControllers() {
    ageController.clear();
    heightController.clear();
    weightController.clear();
    medicalConditionController.clear();
    _selectedMobilityLevel = null;
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    medicalConditionController.dispose();
    super.dispose();
  }
}
