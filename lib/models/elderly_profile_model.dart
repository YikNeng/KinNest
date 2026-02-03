import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an elderly user's profile
class ElderlyProfile {
  final String userId;
  final String email;
  final String name;
  final String role;
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? medicalConditions;
  final String? mobilityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ElderlyProfile({
    required this.userId,
    required this.email,
    required this.role,
    this.age,
    this.height,
    this.weight,
    this.medicalConditions,
    this.mobilityLevel,
    this.createdAt,
    this.updatedAt,
    required this.name,
  });

  /// Create from Firestore document
  factory ElderlyProfile.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ElderlyProfile(
      userId: documentId,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unknown',
      role: data['role']?.toString() ?? 'elderly',
      age: data['age'] as int?,
      height: _toDouble(data['height']),
      weight: _toDouble(data['weight']),
      medicalConditions: data['medicalConditions']?.toString(),
      mobilityLevel: data['mobilityLevel']?.toString(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'age': age,
      'height': height,
      'weight': weight,
      'medicalConditions': medicalConditions,
      'mobilityLevel': mobilityLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Helper to convert to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Create a copy with updated fields
  ElderlyProfile copyWith({
    String? userId,
    String? email,
    String? name,
    String? role,
    int? age,
    double? height,
    double? weight,
    String? medicalConditions,
    String? mobilityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ElderlyProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      mobilityLevel: mobilityLevel ?? this.mobilityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
    );
  }

  /// Display formatted height
  String get formattedHeight =>
      height != null ? '${height!.toStringAsFixed(1)} cm' : 'Not set';

  /// Display formatted weight
  String get formattedWeight =>
      weight != null ? '${weight!.toStringAsFixed(1)} kg' : 'Not set';

  /// Display formatted age
  String get formattedAge => age != null ? '$age years' : 'Not set';

  /// Display medical condition
  String get displayMedicalConditions =>
      medicalConditions?.isEmpty ?? true ? 'Not specified' : medicalConditions!;

  /// Display mobility level
  String get displayMobilityLevel {
    if (mobilityLevel == null || mobilityLevel!.isEmpty) {
      return 'Not specified';
    }

    // Handle legacy values for display
    final Map<String, String> legacyMapping = {
      'low': 'Limited mobility',
      'medium': 'Normal mobility',
      'high': 'Normal mobility',
      'normal': 'Normal mobility',
      'limited': 'Limited mobility',
    };

    String normalizedValue = mobilityLevel!.toLowerCase().trim();

    if (legacyMapping.containsKey(normalizedValue)) {
      return legacyMapping[normalizedValue]!;
    }

    // Return if already in correct format
    return mobilityLevel!;
  }

  void operator [](String other) {}
}
