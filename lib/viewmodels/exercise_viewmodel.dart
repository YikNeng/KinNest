import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';
import '../services/gemini_service.dart';

class ExerciseViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // User profile data
  int? _userAge;
  String? _userHealthCondition;
  String? _userMobilityLevel;

  // Preference inputs
  String _durationType = 'short';
  String _intensity = 'low';

  // State
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;
  ExerciseRoutine? _generatedRoutine;

  // Getters
  String get durationType => _durationType;
  String get intensity => _intensity;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  ExerciseRoutine? get generatedRoutine => _generatedRoutine;
  int? get userAge => _userAge;
  String? get userHealthCondition => _userHealthCondition;
  String? get userMobilityLevel => _userMobilityLevel;

  bool get hasMinimumProfile => _userAge != null;

  String get healthConditionDisplay =>
      _userHealthCondition?.isEmpty ?? true ? '-' : _userHealthCondition!;

  String get mobilityLevelDisplay => _userMobilityLevel?.isEmpty ?? true
      ? 'Not specified'
      : _userMobilityLevel!;

  ExerciseViewModel() {
    _initialize();
  }

  /// Initialize - fetch user profile and load saved routine
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user profile from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userAge = userData['age'] as int?;

        _userHealthCondition = userData['healthCondition'] as String?;
        if (_userHealthCondition != null &&
            _userHealthCondition!.trim().isEmpty) {
          _userHealthCondition = null;
        }

        _userMobilityLevel = userData['mobilityLevel'] as String?;
        if (_userMobilityLevel != null && _userMobilityLevel!.trim().isEmpty) {
          _userMobilityLevel = null;
        }
      }

      // NEW: Load saved routine from Firestore
      await _loadSavedRoutine();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NEW: Load saved routine from Firestore
  Future<void> _loadSavedRoutine() async {
    try {
      ExerciseRoutine? savedRoutine = await _geminiService
          .loadRoutineFromFirestore(userId: _currentUserId);

      if (savedRoutine != null) {
        _generatedRoutine = savedRoutine;
        // Also load the preferences that were used
        _durationType = savedRoutine.routineType;
        // Note: intensity is not stored, so we keep the default
      }
    } catch (e) {
      // Silently fail - it's okay if there's no saved routine
      debugPrint('Failed to load saved routine: $e');
    }
  }

  /// Set duration type
  void setDurationType(String type) {
    _durationType = type;
    notifyListeners();
  }

  /// Set intensity
  void setIntensity(String level) {
    _intensity = level;
    notifyListeners();
  }

  /// Validate inputs
  bool _validateInputs() {
    if (_userAge == null) {
      _errorMessage =
          'Age is required. Please update your profile to include your age.';
      notifyListeners();
      return false;
    }

    if (_userAge! < 50 || _userAge! > 120) {
      _errorMessage =
          'Please ensure your age is correctly set in your profile.';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Generate exercise routine
  Future<bool> generateRoutine() async {
    _errorMessage = null;

    if (!_validateInputs()) {
      return false;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      ExerciseRoutine routine = await _geminiService.generateExerciseRoutine(
        age: _userAge!,
        healthCondition:
            _userHealthCondition ?? 'No specific health conditions',
        mobilityLevel: _userMobilityLevel ?? 'Normal mobility',
        durationType: _durationType,
        intensity: _intensity,
      );

      _generatedRoutine = routine;
      _isGenerating = false;
      notifyListeners();

      // NEW: Auto-save to Firestore after successful generation
      await _saveRoutineInBackground();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  /// NEW: Save routine in background (don't block UI)
  Future<void> _saveRoutineInBackground() async {
    if (_generatedRoutine == null) return;

    try {
      _isSaving = true;
      notifyListeners();

      String routineId = await _geminiService.saveRoutineToFirestore(
        userId: _currentUserId,
        routine: _generatedRoutine!,
      );

      // Update routine with the Firestore ID
      _generatedRoutine = _generatedRoutine!.copyWith(routineId: routineId);

      _isSaving = false;
      notifyListeners();
    } catch (e) {
      // Don't show error to user, just log it
      debugPrint('Failed to save routine in background: $e');
      _isSaving = false;
      notifyListeners();
    }
  }

  /// NEW: Delete routine
  Future<bool> deleteRoutine() async {
    if (_generatedRoutine == null || _generatedRoutine!.routineId == null) {
      reset();
      return true;
    }

    try {
      await _geminiService.deleteRoutineFromFirestore(
        userId: _currentUserId,
        routineId: _generatedRoutine!.routineId!,
      );

      reset();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete routine: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset for new generation
  void reset() {
    _generatedRoutine = null;
    _errorMessage = null;
    notifyListeners();
  }
}
