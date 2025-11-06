class MusicTrackModel {
  final String id;
  final String title;
  final String artist;
  final int durationSeconds;
  final String category;

  MusicTrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.category,
  });

  String getFormattedDuration() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
