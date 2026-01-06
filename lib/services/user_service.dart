import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create user profile in Firestore
  /// Stores user data in 'users' collection with UID as document ID
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role, // "elderly" or "caregiver"
    String? phone, // Elderly-specific fields (optional)
    int? age,
    double? height,
    double? weight,
    String? medicalConditions,
    String? mobilityLevel,
  }) async {
    try {
      // Base user data (common for both roles)
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'profileImageUrl': null,
        'groupIds': [], // Empty array initially
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
}
