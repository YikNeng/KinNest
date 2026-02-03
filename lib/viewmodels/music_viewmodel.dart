import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_track_model.dart';
import '../services/music_service.dart';
import 'dart:async';

class MusicViewModel extends ChangeNotifier {
  final MusicService _musicService = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream subscription
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // State
  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Playback state
  int? _currentPlayingIndex; // Index of currently playing track
  bool _isPlaying = false;
  PlayerState _playerState = PlayerState.stopped;

  // Getters
  List<MusicTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentPlayingIndex => _currentPlayingIndex;
  bool get isPlaying => _isPlaying;

  MusicViewModel() {
    _initialize();
  }

  /// Initialize to load tracks and setup audio player
  Future<void> _initialize() async {
    _setupAudioPlayer();
    await loadTracks();
  }

  /// Setup audio player listeners
  void _setupAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      PlayerState state,
    ) {
      _playerState = state;
      _isPlaying = (state == PlayerState.playing);

      // When track completes, reset state
      if (state == PlayerState.completed) {
        _currentPlayingIndex = null;
        _isPlaying = false;
      }

      notifyListeners();
    });
  }

  /// Load all music tracks
  Future<void> loadTracks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tracks = await _musicService.fetchMusicTracks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play or pause a track
  Future<void> togglePlayPause(int index) async {
    try {
      MusicTrack track = _tracks[index];

      // Tapping the same track that's currently playing
      if (_currentPlayingIndex == index && _isPlaying) {
        await _audioPlayer.pause();
        _isPlaying = false;
        notifyListeners();
        return;
      }

      // Tapping the same track that's paused (resume)
      if (_currentPlayingIndex == index && !_isPlaying) {
        await _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
        return;
      }

      // Playing a different track (or first time playing)
      if (_currentPlayingIndex != null) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.play(AssetSource(track.path));

      _currentPlayingIndex = index;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play track: ${e.toString()}';
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _currentPlayingIndex = null;
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();

    // Stop and dispose audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();

    super.dispose();
  }
}
