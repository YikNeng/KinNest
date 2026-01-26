import 'dart:async'; // Import this
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

  // STREAM SUBSCRIPTION (This is the key fix)
  StreamSubscription<DocumentSnapshot>? _userProfileSubscription;

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

  /// Initialize - LISTEN to real-time updates
  void _initialize() {
    _isLoading = true;
    notifyListeners();

    // FIX: Use snapshots() instead of get() to listen for changes
    _userProfileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              Map<String, dynamic> userData =
                  snapshot.data() as Map<String, dynamic>;

              // 1. Update Age
              _userAge = userData['age'] as int?;

              // 2. Update Medical Conditions (handle empty/null)
              String? med = userData['medicalConditions'] as String?;
              if (med != null && med.trim().isEmpty) med = null;
              _userMedicalConditions = med;

              // 3. Update Mobility (handle empty/null)
              String? mob = userData['mobilityLevel'] as String?;
              if (mob != null && mob.trim().isEmpty) mob = null;
              _userMobilityLevel = mob;

              // 4. Notify UI immediately
              _isLoading = false;
              notifyListeners();
            }
          },
          onError: (e) {
            _errorMessage = 'Failed to load profile: $e';
            _isLoading = false;
            notifyListeners();
          },
        );

    // Load saved routine separately
    _loadSavedRoutine();
  }

  /// NEW: Load saved routine from Firestore
  Future<void> _loadSavedRoutine() async {
    try {
      ExerciseRoutine? savedRoutine = await _geminiService
          .loadRoutineFromFirestore(userId: _currentUserId);

      if (savedRoutine != null) {
        _generatedRoutine = savedRoutine;
        _durationType = savedRoutine.routineType;
        notifyListeners(); // Update UI if routine loaded
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
      _errorMessage = 'Age is required. Please update your profile.';
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
      // NOTE: We don't need _refreshUserProfile() anymore because
      // the stream above keeps our variables fresh automatically!

      // Step 1: Generate routine from Gemini
      ExerciseRoutine routine = await _geminiService.generateExerciseRoutine(
        age: _userAge!,
        medicalConditions:
            _userMedicalConditions ?? 'No specific medical conditions',
        mobilityLevel: _userMobilityLevel ?? 'Normal mobility',
        durationType: _durationType,
        intensity: _intensity,
      );

      // Step 2: Search YouTube (Video logic remains same)
      List<Exercise> exercisesWithVideos = [];
      for (int i = 0; i < routine.exercises.length; i++) {
        Exercise exercise = routine.exercises[i];
        String? videoUrl = await _youtubeService.searchExerciseVideo(
          exercise.name,
        );

        exercisesWithVideos.add(
          Exercise(
            name: exercise.name,
            description: exercise.description,
            steps: exercise.steps,
            durationMinutes: exercise.durationMinutes,
            safetyNotes: exercise.safetyNotes,
            videoUrl: videoUrl,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Step 3: Create Final Routine
      _generatedRoutine = ExerciseRoutine(
        routineType: routine.routineType,
        durationMinutes: routine.durationMinutes,
        exercises: exercisesWithVideos,
        generalAdvice: routine.generalAdvice,
        createdAt: DateTime.now(),
      );

      _isGenerating = false;
      notifyListeners();

      // Step 4: Auto-save
      await _saveRoutineInBackground();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveRoutineInBackground() async {
    if (_generatedRoutine == null) return;
    try {
      String routineId = await _geminiService.saveRoutineToFirestore(
        userId: _currentUserId,
        routine: _generatedRoutine!,
      );
      _generatedRoutine = _generatedRoutine!.copyWith(routineId: routineId);
    } catch (e) {
      debugPrint('❌ Failed to save routine: $e');
    }
  }

  Future<bool> deleteRoutine() async {
    if (_generatedRoutine?.routineId == null) {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _generatedRoutine = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // CRITICAL: Cancel the listener when app closes/logs out
    _userProfileSubscription?.cancel();
    super.dispose();
  }
}
