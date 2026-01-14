import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/music_track_model.dart';

class MusicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch all relaxing music tracks from Firestore
  Future<List<MusicTrack>> fetchMusicTracks() async {
    try {
      // Query the 'relaxingMusic' collection
      QuerySnapshot snapshot = await _firestore
          .collection('relaxingMusic')
          .orderBy('created_at', descending: false)
          .get();

      List<MusicTrack> tracks = [];
      for (var doc in snapshot.docs) {
        tracks.add(
          MusicTrack.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        );
      }

      return tracks;
    } catch (e) {
      throw Exception('Failed to fetch music tracks: $e');
    }
  }

  /// Get download URL from Firebase Storage
  ///
  /// How it works:
  /// 1. Takes storage path (e.g., "music/relaxing_ocean.mp3")
  /// 2. Gets reference to that file in Firebase Storage
  /// 3. Retrieves the download URL
  /// 4. This URL can be used to stream/download the audio file
  Future<String> getAudioUrl(String storagePath) async {
    try {
      // Get reference to the file in Firebase Storage
      Reference ref = _storage.ref(storagePath);

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to get audio URL: $e');
    }
  }

  /// Add a new music track (admin only - for testing)
  Future<String> addMusicTrack(MusicTrack track) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('relaxingMusic')
          .add(track.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add music track: $e');
    }
  }

  /// Delete a music track (admin only - for testing)
  Future<void> deleteMusicTrack(String trackId) async {
    try {
      await _firestore.collection('relaxingMusic').doc(trackId).delete();
    } catch (e) {
      throw Exception('Failed to delete music track: $e');
    }
  }
}
