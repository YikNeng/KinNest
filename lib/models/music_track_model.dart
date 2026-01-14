import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a relaxing music track
class MusicTrack {
  final String trackId;
  final String title;
  final String storagePath; // Firebase Storage path
  final String? description;
  final int durationSeconds;
  final DateTime createdAt;

  MusicTrack({
    required this.trackId,
    required this.title,
    required this.storagePath,
    this.description,
    required this.durationSeconds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Firestore document
  factory MusicTrack.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return MusicTrack(
      trackId: documentId,
      title: data['title']?.toString() ?? 'Unknown Track',
      storagePath: data['storage_path']?.toString() ?? '',
      description: data['description']?.toString(),
      durationSeconds: data['duration_seconds'] as int? ?? 0,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'storage_path': storagePath,
      'description': description,
      'duration_seconds': durationSeconds,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    int minutes = durationSeconds ~/ 60;
    int seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
