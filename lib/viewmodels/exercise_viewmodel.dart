import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';
import '../services/gemini_service.dart';
import '../services/youtube_service.dart';

class ExerciseViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final YouTubeService _youtubeService = YouTubeService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // User profile data
  int? _userAge;
  String? _userMedicalConditions;
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
  String? get userMedicalConditions => _userMedicalConditions;
  String? get userMobilityLevel => _userMobilityLevel;

  bool get hasMinimumProfile => _userAge != null;

  String get medicalConditionsDisplay =>
      _userMedicalConditions?.isEmpty ?? true ? '-' : _userMedicalConditions!;

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

        _userMedicalConditions = userData['medicalConditions'] as String?;
        if (_userMedicalConditions != null &&
            _userMedicalConditions!.trim().isEmpty) {
          _userMedicalConditions = null;
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
      debugPrint('📥 Loading routine from Firestore...');

      ExerciseRoutine? savedRoutine = await _geminiService
          .loadRoutineFromFirestore(userId: _currentUserId);

      if (savedRoutine != null) {
        debugPrint(
          '✅ Routine loaded: ${savedRoutine.exercises.length} exercises',
        );
        for (var ex in savedRoutine.exercises) {
          debugPrint('   - ${ex.name}: ${ex.videoUrl ?? "NO VIDEO"}');
        }

        _generatedRoutine = savedRoutine;
        _durationType = savedRoutine.routineType;
      } else {
        debugPrint('ℹ️ No saved routine found');
      }
    } catch (e) {
      debugPrint('❌ Failed to load saved routine: $e');
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
      // Step 1: Generate routine from Gemini (without video URLs)
      ExerciseRoutine routine = await _geminiService.generateExerciseRoutine(
        age: _userAge!,
        medicalConditions:
            _userMedicalConditions ?? 'No specific medical conditions',
        mobilityLevel: _userMobilityLevel ?? 'Normal mobility',
        durationType: _durationType,
        intensity: _intensity,
      );

      debugPrint('✅ Gemini generated ${routine.exercises.length} exercises');

      // Step 2: Search YouTube for real video URLs
      List<Exercise> exercisesWithVideos = [];

      for (int i = 0; i < routine.exercises.length; i++) {
        Exercise exercise = routine.exercises[i];

        debugPrint('🔍 Searching video for: ${exercise.name}');

        String? videoUrl = await _youtubeService.searchExerciseVideo(
          exercise.name,
        );

        debugPrint('${videoUrl != null ? "✅" : "❌"} Video URL: $videoUrl');

        // Create new exercise with video URL
        exercisesWithVideos.add(
          Exercise(
            name: exercise.name,
            description: exercise.description,
            steps: exercise.steps,
            durationMinutes: exercise.durationMinutes,
            safetyNotes: exercise.safetyNotes,
            videoUrl: videoUrl, // Real YouTube URL or null
          ),
        );

        // Small delay to respect API limits
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Step 3: Create routine with video URLs
      _generatedRoutine = ExerciseRoutine(
        routineType: routine.routineType,
        durationMinutes: routine.durationMinutes,
        exercises: exercisesWithVideos,
        generalAdvice: routine.generalAdvice,
        createdAt: DateTime.now(),
      );

      debugPrint(
        '✅ Routine created with ${exercisesWithVideos.length} exercises',
      );
      for (var ex in exercisesWithVideos) {
        debugPrint('   - ${ex.name}: ${ex.videoUrl ?? "NO VIDEO"}');
      }

      _isGenerating = false;
      notifyListeners();

      // Step 4: Auto-save to Firestore (with video URLs)
      await _saveRoutineInBackground();

      return true;
    } catch (e) {
      debugPrint('❌ Error generating routine: $e');
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

      debugPrint('💾 Saving routine to Firestore...');

      String routineId = await _geminiService.saveRoutineToFirestore(
        userId: _currentUserId,
        routine: _generatedRoutine!,
      );

      debugPrint('✅ Routine saved with ID: $routineId');

      // Update routine with the Firestore ID
      _generatedRoutine = _generatedRoutine!.copyWith(routineId: routineId);

      _isSaving = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to save routine: $e');
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
