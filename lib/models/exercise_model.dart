class ExerciseModel {
  final String id;
  final String name;
  final String type;
  final int frequencyPerWeek;
  final int durationMinutes;
  final String description;
  final String difficulty;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.frequencyPerWeek,
    required this.durationMinutes,
    required this.description,
    required this.difficulty,
  });

  String getFrequencyText() {
    return '$frequencyPerWeek times per week';
  }

  String getDurationText() {
    return '$durationMinutes minutes per session';
  }
}

class ExerciseRoutine {
  final String id;
  final String title;
  final String description;
  final List<ExerciseModel> exercises;
  final DateTime createdAt;
  final String targetGoal;

  ExerciseRoutine({
    required this.id,
    required this.title,
    required this.description,
    required this.exercises,
    required this.createdAt,
    required this.targetGoal,
  });
}

class ElderlyProfile {
  final int age;
  final double height;
  final double weight;
  final List<String> chronicDiseases;
  final String activityLevel;

  ElderlyProfile({
    required this.age,
    required this.height,
    required this.weight,
    required this.chronicDiseases,
    required this.activityLevel,
  });

  double getBMI() {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }
}
