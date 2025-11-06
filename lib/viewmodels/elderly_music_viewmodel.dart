import 'package:flutter/material.dart';
import '../models/music_track_model.dart';

class ElderlyMusicViewModel extends ChangeNotifier {
  List<MusicTrackModel> _musicTracks = [];
  String? _currentlyPlayingTrackId;
  bool _isLoading = false;

  List<MusicTrackModel> get musicTracks => _musicTracks;
  String? get currentlyPlayingTrackId => _currentlyPlayingTrackId;
  bool get isLoading => _isLoading;

  ElderlyMusicViewModel() {
    _loadDummyMusicTracks();
  }

  void _loadDummyMusicTracks() {
    _isLoading = true;
    notifyListeners();

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _musicTracks = [
        MusicTrackModel(
          id: '1',
          title: 'Peaceful Piano',
          artist: 'Relaxation Sounds',
          durationSeconds: 240,
          category: 'Classical',
        ),
        MusicTrackModel(
          id: '2',
          title: 'Ocean Waves',
          artist: 'Nature Sounds',
          durationSeconds: 300,
          category: 'Nature',
        ),
        MusicTrackModel(
          id: '3',
          title: 'Morning Meditation',
          artist: 'Calm Music',
          durationSeconds: 180,
          category: 'Meditation',
        ),
        MusicTrackModel(
          id: '4',
          title: 'Gentle Rain',
          artist: 'Nature Sounds',
          durationSeconds: 360,
          category: 'Nature',
        ),
        MusicTrackModel(
          id: '5',
          title: 'Classical Guitar',
          artist: 'Instrumental',
          durationSeconds: 210,
          category: 'Classical',
        ),
        MusicTrackModel(
          id: '6',
          title: 'Forest Birds',
          artist: 'Nature Sounds',
          durationSeconds: 270,
          category: 'Nature',
        ),
        MusicTrackModel(
          id: '7',
          title: 'Soft Jazz',
          artist: 'Smooth Jazz',
          durationSeconds: 195,
          category: 'Jazz',
        ),
        MusicTrackModel(
          id: '8',
          title: 'Evening Relaxation',
          artist: 'Calm Music',
          durationSeconds: 330,
          category: 'Meditation',
        ),
        MusicTrackModel(
          id: '9',
          title: 'Bamboo Flute',
          artist: 'Traditional',
          durationSeconds: 225,
          category: 'Traditional',
        ),
        MusicTrackModel(
          id: '10',
          title: 'White Noise',
          artist: 'Sleep Sounds',
          durationSeconds: 600,
          category: 'Sleep',
        ),
      ];

      _isLoading = false;
      notifyListeners();
    });
  }

  bool isPlaying(String trackId) {
    return _currentlyPlayingTrackId == trackId;
  }

  // TODO: Future integration point - connect to audio player service
  void togglePlayTrack(String trackId) {
    if (_currentlyPlayingTrackId == trackId) {
      // Stop playing
      _currentlyPlayingTrackId = null;
    } else {
      // Start playing
      _currentlyPlayingTrackId = trackId;

      // Simulate track completion after duration
      final track = _musicTracks.firstWhere((t) => t.id == trackId);
      Future.delayed(Duration(seconds: track.durationSeconds), () {
        if (_currentlyPlayingTrackId == trackId) {
          _currentlyPlayingTrackId = null;
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  void stopAllTracks() {
    _currentlyPlayingTrackId = null;
    notifyListeners();
  }

  void refreshTracks() {
    _loadDummyMusicTracks();
  }
}
