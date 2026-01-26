import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Login with email and password
  /// Returns user role on success, throws exception on failure
  Future<String> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Firebase Auth (This creates the session)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Fetch user role from Firestore
      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      // Check 1: Does the document exist?
      if (!userDoc.exists) {
        // CRITICAL: Rollback the auth session so user isn't stuck "logged in"
        await _auth.signOut();
        throw Exception('User profile not found in database');
      }

      // Check 2: Does the data exist and contain 'role'?
      // We use .data() and Map access to avoid "Bad state" crashes
      final data = userDoc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('role')) {
        // CRITICAL: Rollback the auth session
        await _auth.signOut();
        throw Exception('User account is missing role information');
      }

      // Safe to access now
      String role = data['role'] as String;
      return role;
    } on FirebaseAuthException catch (e) {
      // Auth failed, no session created, no need to sign out
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      // If we crashed AFTER auth but BEFORE returning, ensure we clean up
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      // Clean up the error message for the UI
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      throw Exception(msg);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return userDoc.get('role') as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  /// Register new user with email and password
  /// Returns the created user's UID
  Future<String> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Return the user's UID
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('This email is already registered');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled');
        default:
          throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }
}
