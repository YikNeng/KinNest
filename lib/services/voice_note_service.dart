import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class VoiceNoteService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload voice note to Firebase Storage
  /// Returns the download URL
  Future<String> uploadVoiceNote({
    required File file,
    required String groupId,
    required String reminderId,
  }) async {
    try {
      // Generate unique filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(file.path);
      String fileName = 'voice_note_${timestamp}$extension';

      // Storage path: voice_notes/{groupId}/{reminderId}/{fileName}
      String storagePath = 'voice_notes/$groupId/$reminderId/$fileName';

      // Upload file
      Reference ref = _storage.ref().child(storagePath);
      UploadTask uploadTask = ref.putFile(file);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload voice note: $e');
    }
  }

  /// Delete voice note from Firebase Storage
  Future<void> deleteVoiceNote(String downloadUrl) async {
    try {
      // Extract storage path from URL
      Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete voice note: $e');
    }
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}
