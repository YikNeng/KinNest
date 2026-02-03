import '../models/music_track_model.dart';

class MusicService {
  /// Fetch all relaxing music tracks
  Future<List<MusicTrack>> fetchMusicTracks() async {
    try {
      return [
        MusicTrack(
          title: "Ambient Music",
          path: "music/ambient_music.mp3",
          duration: "9:18",
        ),
        MusicTrack(
          title: "Gentle Rainforest Rain",
          path: "music/rain_audio.mp3",
          duration: "4:00",
        ),
        MusicTrack(
          title: "Surreal Forest Music",
          path: "music/forest_music.mp3",
          duration: "2:01",
        ),
        MusicTrack(
          title: "Ocean Wave",
          path: "music/ocean_wave.mp3",
          duration: "1:55",
        ),
        MusicTrack(
          title: "Calming Music",
          path: "music/calm_music.mp3",
          duration: "3:44",
        ),
      ];
    } catch (e) {
      throw Exception('Failed to fetch music tracks: $e');
    }
  }
}
