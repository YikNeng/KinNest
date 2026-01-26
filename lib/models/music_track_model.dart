class MusicTrack {
  final String title;
  final String path; // Local path (e.g., 'music/song.mp3')
  final String duration; // String like "3:00"

  MusicTrack({required this.title, required this.path, required this.duration});

  // Getter for formatted duration if you store it differently
  String get formattedDuration => duration;
}
