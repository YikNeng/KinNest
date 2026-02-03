import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latest_fyp/models/elderly_profile_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create user profile in Firestore
  /// Stores user data in 'users' collection with UID as document ID
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
    String? phone,
    int? age,
    double? height,
    double? weight,
    String? medicalConditions,
    String? mobilityLevel,
  }) async {
    try {
      // Base user data
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'profileImageUrl': null,
        'groupIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add elderly-specific fields if role is "elderly"
      if (role == 'elderly') {
        userData['age'] = age;
        userData['height'] = height;
        userData['weight'] = weight;
        userData['medicalConditions'] = medicalConditions;
        userData['mobilityLevel'] = mobilityLevel;
      }

      // Save to Firestore 'users' collection
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get elderly profile by user ID
  Future<ElderlyProfile?> getElderlyProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ElderlyProfile.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Get current user's profile
  Future<ElderlyProfile?> getCurrentUserProfile() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    return await getElderlyProfile(userId);
  }

  /// Update elderly profile
  Future<void> updateElderlyProfile({
    required String userId,
    int? age,
    double? height,
    double? weight,
    String? medicalConditions,
    String? mobilityLevel,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only include fields that are provided
      if (age != null) updates['age'] = age;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (medicalConditions != null) {
        updates['medicalConditions'] = medicalConditions;
      }
      if (mobilityLevel != null) updates['mobilityLevel'] = mobilityLevel;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update user email in Firestore
  Future<void> updateUserEmail(String userId, String newEmail) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update email in database: $e');
    }
  }

  // Add inside UserService class
  Future<void> saveUserToken(String userId, String? token) async {
    if (token == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving token: $e');
    }
  }
}
