import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

class ElderlyExerciseViewModel extends ChangeNotifier {
  ExerciseRoutine? _currentRoutine;
  ElderlyProfile? _elderlyProfile;
  bool _isLoading = false;
  bool _isGeneratingPlan = false;

  ExerciseRoutine? get currentRoutine => _currentRoutine;
  ElderlyProfile? get elderlyProfile => _elderlyProfile;
  bool get isLoading => _isLoading;
  bool get isGeneratingPlan => _isGeneratingPlan;
  bool get hasPlannedRoutine => _currentRoutine != null;

  ElderlyExerciseViewModel() {
    _loadDummyData();
  }

  void _loadDummyData() {
    _isLoading = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 300), () {
      // Simulate loading elderly profile from local storage
      _elderlyProfile = ElderlyProfile(
        age: 68,
        height: 165,
        weight: 70,
        chronicDiseases: ['Diabetes', 'Hypertension'],
        activityLevel: 'Low',
      );

      // Change this flag to test different states
      // true = has routine, false = no routine
      bool hasExistingRoutine = false;

      if (hasExistingRoutine) {
        _currentRoutine = _createDummyRoutine();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  ExerciseRoutine _createDummyRoutine() {
    return ExerciseRoutine(
      id: '1',
      title: 'Gentle Senior Fitness Plan',
      description:
          'A personalized low-impact exercise routine designed for your health profile',
      targetGoal: 'Improve flexibility and maintain cardiovascular health',
      createdAt: DateTime.now(),
      exercises: [
        ExerciseModel(
          id: '1',
          name: 'Chair Sitting Exercise',
          type: 'Strength',
          frequencyPerWeek: 3,
          durationMinutes: 10,
          description: 'Sit-to-stand exercises using a sturdy chair',
          difficulty: 'Easy',
        ),
        ExerciseModel(
          id: '2',
          name: 'Gentle Walking',
          type: 'Cardio',
          frequencyPerWeek: 5,
          durationMinutes: 15,
          description: 'Slow-paced walking around the house or garden',
          difficulty: 'Easy',
        ),
        ExerciseModel(
          id: '3',
          name: 'Arm Stretches',
          type: 'Flexibility',
          frequencyPerWeek: 7,
          durationMinutes: 5,
          description: 'Simple arm and shoulder stretching exercises',
          difficulty: 'Very Easy',
        ),
      ],
    );
  }

  // TODO: Replace with real AI service call
  Future<void> generateExercisePlan() async {
    if (_elderlyProfile == null) {
      // Load profile if not loaded yet
      _elderlyProfile = ElderlyProfile(
        age: 68,
        height: 165,
        weight: 70,
        chronicDiseases: ['Diabetes', 'Hypertension'],
        activityLevel: 'Low',
      );
    }

    _isGeneratingPlan = true;
    notifyListeners();

    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2));

    // Hardcoded logic based on profile data
    List<ExerciseModel> exercises = [];

    final age = _elderlyProfile!.age;
    final bmi = _elderlyProfile!.getBMI();
    final hasDiabetes = _elderlyProfile!.chronicDiseases.contains('Diabetes');
    final hasHypertension =
        _elderlyProfile!.chronicDiseases.contains('Hypertension');

    // Generate exercises based on profile
    if (age >= 65) {
      exercises.add(ExerciseModel(
        id: '1',
        name: 'Chair Sitting Exercise',
        type: 'Strength',
        frequencyPerWeek: 3,
        durationMinutes: 10,
        description: 'Sit-to-stand exercises using a sturdy chair',
        difficulty: 'Easy',
      ));
    }

    if (hasHypertension) {
      exercises.add(ExerciseModel(
        id: '2',
        name: 'Gentle Walking',
        type: 'Cardio',
        frequencyPerWeek: 5,
        durationMinutes: 15,
        description: 'Slow-paced walking to improve heart health',
        difficulty: 'Easy',
      ));
    } else {
      exercises.add(ExerciseModel(
        id: '2',
        name: 'Brisk Walking',
        type: 'Cardio',
        frequencyPerWeek: 4,
        durationMinutes: 20,
        description: 'Moderate-paced walking for cardiovascular fitness',
        difficulty: 'Moderate',
      ));
    }

    exercises.add(ExerciseModel(
      id: '3',
      name: 'Arm Stretches',
      type: 'Flexibility',
      frequencyPerWeek: 7,
      durationMinutes: 5,
      description: 'Simple arm and shoulder stretching exercises',
      difficulty: 'Very Easy',
    ));

    if (!hasHypertension && age < 70) {
      exercises.add(ExerciseModel(
        id: '4',
        name: 'Light Leg Lifts',
        type: 'Strength',
        frequencyPerWeek: 3,
        durationMinutes: 8,
        description: 'Gentle leg strengthening while seated',
        difficulty: 'Easy',
      ));
    }

    if (hasDiabetes) {
      exercises.add(ExerciseModel(
        id: '5',
        name: 'Balance Training',
        type: 'Balance',
        frequencyPerWeek: 3,
        durationMinutes: 10,
        description: 'Standing balance exercises for stability',
        difficulty: 'Easy',
      ));
    }

    String planTitle = 'Personalized Exercise Plan';
    String description =
        'A customized routine based on your age ($age), BMI (${bmi.toStringAsFixed(1)}), and health conditions';
    String targetGoal =
        'Maintain mobility, improve strength, and support overall health';

    if (hasDiabetes && hasHypertension) {
      description +=
          '. Focuses on gentle cardiovascular and balance exercises suitable for diabetes and hypertension management';
    } else if (hasDiabetes) {
      description +=
          '. Includes balance training important for diabetes management';
    } else if (hasHypertension) {
      description +=
          '. Emphasizes gentle cardio suitable for blood pressure control';
    }

    _currentRoutine = ExerciseRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: planTitle,
      description: description,
      targetGoal: targetGoal,
      createdAt: DateTime.now(),
      exercises: exercises,
    );

    _isGeneratingPlan = false;
    notifyListeners();
  }

  void clearRoutine() {
    _currentRoutine = null;
    notifyListeners();
  }

  void refreshData() {
    _loadDummyData();
  }
}
