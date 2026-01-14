import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a single exercise
class Exercise {
  final String name;
  final String description;
  final List<String> steps;
  final int durationMinutes;
  final String safetyNotes;
  final String? videoUrl;

  Exercise({
    required this.name,
    required this.description,
    required this.steps,
    required this.durationMinutes,
    required this.safetyNotes,
    this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name']?.toString() ?? 'Unknown Exercise',
      description: json['description']?.toString() ?? '',
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      durationMinutes: json['duration_minutes'] as int? ?? 5,
      safetyNotes: json['safety_notes']?.toString() ?? '',
      videoUrl: json['video_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'steps': steps,
      'duration_minutes': durationMinutes,
      'safety_notes': safetyNotes,
      'video_url': videoUrl,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'steps': steps,
      'duration_minutes': durationMinutes,
      'safety_notes': safetyNotes,
      'video_url': videoUrl,
    };
  }

  factory Exercise.fromFirestore(Map<String, dynamic> data) {
    return Exercise(
      name: data['name']?.toString() ?? 'Unknown Exercise',
      description: data['description']?.toString() ?? '',
      steps:
          (data['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      durationMinutes: data['duration_minutes'] as int? ?? 5,
      safetyNotes: data['safety_notes']?.toString() ?? '',
      videoUrl: data['video_url']?.toString(),
    );
  }
}

/// Model for complete exercise routine
class ExerciseRoutine {
  final String routineType; // 'short' or 'long_term'
  final int durationMinutes;
  final List<Exercise> exercises;
  final String generalAdvice;
  final DateTime createdAt;
  final String? routineId;

  ExerciseRoutine({
    required this.routineType,
    required this.durationMinutes,
    required this.exercises,
    required this.generalAdvice,
    DateTime? createdAt,
    this.routineId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExerciseRoutine.fromJson(Map<String, dynamic> json) {
    return ExerciseRoutine(
      routineType: json['routine_type']?.toString() ?? 'short',
      durationMinutes: json['duration_minutes'] as int? ?? 15,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generalAdvice: json['general_advice']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      routineId: json['routine_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routine_type': routineType,
      'duration_minutes': durationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'general_advice': generalAdvice,
      'created_at': createdAt.toIso8601String(),
      'routine_id': routineId,
    };
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'routine_type': routineType,
      'duration_minutes': durationMinutes,
      'exercises': exercises.map((e) => e.toFirestore()).toList(),
      'general_advice': generalAdvice,
      'created_at': createdAt,
      'updated_at': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory ExerciseRoutine.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ExerciseRoutine(
      routineType: data['routine_type']?.toString() ?? 'short',
      durationMinutes: data['duration_minutes'] as int? ?? 15,
      exercises:
          (data['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromFirestore(e as Map<String, dynamic>))
              .toList() ??
          [],
      generalAdvice: data['general_advice']?.toString() ?? '',
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      routineId: documentId,
    );
  }

  /// Get user-friendly routine type display
  String get routineTypeDisplay {
    switch (routineType) {
      case 'short':
        return 'Short Routine (15-30 min)';
      case 'long_term':
        return 'Long-term Plan';
      default:
        return 'Exercise Routine';
    }
  }

  /// Create a copy with updated fields
  ExerciseRoutine copyWith({
    String? routineType,
    int? durationMinutes,
    List<Exercise>? exercises,
    String? generalAdvice,
    DateTime? createdAt,
    String? routineId,
  }) {
    return ExerciseRoutine(
      routineType: routineType ?? this.routineType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      generalAdvice: generalAdvice ?? this.generalAdvice,
      createdAt: createdAt ?? this.createdAt,
      routineId: routineId ?? this.routineId,
    );
  }
}

/// Model for exercise preferences (unchanged)
class ExercisePreference {
  final String durationType; // 'short' or 'long_term'
  final String intensity; // 'low' or 'medium'

  ExercisePreference({required this.durationType, required this.intensity});

  Map<String, dynamic> toJson() {
    return {'duration_type': durationType, 'intensity': intensity};
  }
}
