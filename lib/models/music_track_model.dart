class MusicTrack {
  final String title;
  final String path;
  final String duration;

  MusicTrack({required this.title, required this.path, required this.duration});

  // Getter for formatted duration
  String get formattedDuration => duration;
}
