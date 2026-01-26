import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_track_model.dart';
import '../services/music_service.dart';
import 'dart:async';

class MusicViewModel extends ChangeNotifier {
  final MusicService _musicService = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream subscription - MUST be stored and cancelled
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

  /// Initialize - load tracks and setup audio player
  Future<void> _initialize() async {
    _setupAudioPlayer();
    await loadTracks();
  }

  /// Setup audio player listeners
  ///
  /// How it works:
  /// - Listens to player state changes (playing, paused, stopped, completed)
  /// - When track completes, resets the playing state
  /// - Updates UI through notifyListeners()
  /// - IMPORTANT: Stores subscription so it can be cancelled in dispose()
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

  /// Load all music tracks from Firestore
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
  ///
  /// How multiple tracks are handled safely:
  /// 1. If tapping same track that's playing → pause it
  /// 2. If tapping same track that's paused → resume it
  /// 3. If tapping different track → stop current, play new one
  ///
  /// This ensures only one track plays at a time
  Future<void> togglePlayPause(int index) async {
    try {
      MusicTrack track = _tracks[index];

      // Case 1: Tapping the same track that's currently playing
      if (_currentPlayingIndex == index && _isPlaying) {
        await _audioPlayer.pause();
        _isPlaying = false;
        notifyListeners();
        return;
      }

      // Case 2: Tapping the same track that's paused (resume)
      if (_currentPlayingIndex == index && !_isPlaying) {
        await _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
        return;
      }

      // Case 3: Playing a different track (or first time playing)
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
    // CRITICAL: Cancel stream subscription BEFORE disposing audio player
    // This prevents the stream from firing events after dispose
    _playerStateSubscription?.cancel();

    // Stop and dispose audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();

    super.dispose();
  }
}
