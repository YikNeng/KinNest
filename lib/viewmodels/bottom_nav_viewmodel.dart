import 'package:flutter/material.dart';

/// Manages bottom navigation tab state
/// Used by both Elderly and Caregiver scaffolds
class BottomNavViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  // Getter
  int get currentIndex => _currentIndex;

  /// Set current tab index
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Reset to first tab (useful when logging out or switching contexts)
  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}
