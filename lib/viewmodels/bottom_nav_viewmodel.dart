import 'package:flutter/material.dart';

/// Manages bottom navigation tab state
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

  /// Reset to first tab
  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}
