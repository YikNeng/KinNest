import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Provider that listens to Firebase Auth state changes
/// Used by GoRouter to determine authentication status
class AuthStateProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isInitialized = false;

  AuthStateProvider() {
    _init();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  /// Initialize auth state listener
  void _init() {
    // Listen to Firebase Auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      notifyListeners(); // Notify GoRouter to re-evaluate routes
    });
  }

  /// Get current user ID (null if not authenticated)
  String? get userId => _user?.uid;
}
