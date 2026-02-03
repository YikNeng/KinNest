import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user details from Firestore
  Future<Map<String, dynamic>?> getCurrentUserDetails() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      userData['uid'] = userId;
      return userData;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  /// Get current user details stream
  Stream<Map<String, dynamic>?> getCurrentUserDetailsStream() {
    try {
      String userId = _auth.currentUser!.uid;
      return _firestore.collection('users').doc(userId).snapshots().map((
        snapshot,
      ) {
        if (!snapshot.exists) return null;
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
        userData['uid'] = userId;
        return userData;
      });
    } catch (e) {
      throw Exception('Failed to stream user details: $e');
    }
  }

  /// Get groups user belongs to with role information
  Future<List<Map<String, dynamic>>> getUserGroupsWithRoles(
    String userId,
  ) async {
    try {
      List<Map<String, dynamic>> userGroups = [];

      // Query groups where user is admin
      QuerySnapshot adminGroupsSnapshot = await _firestore
          .collection('groups')
          .where('adminId', isEqualTo: userId)
          .get();

      for (var doc in adminGroupsSnapshot.docs) {
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        userGroups.add({
          'groupId': doc.id,
          'groupName': groupData['groupName'] ?? 'Unknown Group',
          'role': 'Admin',
          'memberCount': (groupData['memberIds'] as List?)?.length ?? 0,
        });
      }

      // Query groups where user is a member
      QuerySnapshot memberGroupsSnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      for (var doc in memberGroupsSnapshot.docs) {
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        userGroups.add({
          'groupId': doc.id,
          'groupName': groupData['groupName'] ?? 'Unknown Group',
          'role': 'Member',
          'memberCount': (groupData['memberIds'] as List?)?.length ?? 0,
        });
      }

      return userGroups;
    } catch (e) {
      throw Exception('Failed to get user groups: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String name,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update user email (Firebase Auth + Firestore)
  Future<void> updateUserEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user before email change
      String currentEmail = user.email!;
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth
      await user.verifyBeforeUpdateEmail(newEmail);

      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('Email already in use');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email address');
      }
      throw Exception('Failed to update email: $e');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      String currentEmail = user.email!;
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Current password is incorrect');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('New password is too weak');
      }
      throw Exception('Failed to change password: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    // Basic email regex
    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Get current user email
  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? '';
  }
}
