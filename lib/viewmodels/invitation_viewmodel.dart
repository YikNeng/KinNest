import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/invitation_service.dart';

class InvitationViewModel extends ChangeNotifier {
  final InvitationService _invitationService = InvitationService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String _currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  // State variables
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _processingInvitationId;

  // Getters
  List<Map<String, dynamic>> get invitations => _invitations;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasInvitations => _invitations.isNotEmpty;
  int get invitationCount => _invitations.length;

  InvitationViewModel() {
    fetchInvitations();
  }

  /// Fetch pending invitations for current user
  Future<void> fetchInvitations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invitations = await _invitationService
          .getPendingInvitationsForCurrentUser(_currentUserEmail);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept invitation
  Future<bool> acceptInvitation(String groupId, String role) async {
    _isProcessing = true;
    _processingInvitationId = groupId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _invitationService.acceptInvitation(
        groupId: groupId,
        userEmail: _currentUserEmail,
        userId: _currentUserId,
        role: role,
      );

      // Remove from local list
      _invitations.removeWhere((inv) => inv['groupId'] == groupId);

      _isProcessing = false;
      _processingInvitationId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      _processingInvitationId = null;
      notifyListeners();
      return false;
    }
  }

  /// Reject invitation
  Future<bool> rejectInvitation(String groupId) async {
    _isProcessing = true;
    _processingInvitationId = groupId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _invitationService.rejectInvitation(
        groupId: groupId,
        userEmail: _currentUserEmail,
        userId: _currentUserId,
      );

      // Remove from local list
      _invitations.removeWhere((inv) => inv['groupId'] == groupId);

      _isProcessing = false;
      _processingInvitationId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      _processingInvitationId = null;
      notifyListeners();
      return false;
    }
  }

  /// Check if specific invitation is being processed
  bool isInvitationProcessing(String groupId) {
    return _isProcessing && _processingInvitationId == groupId;
  }

  /// Format invitation date
  String formatInvitationDate(Timestamp timestamp) {
    return _invitationService.formatInvitationDate(timestamp);
  }

  /// Get role display text
  String getRoleDisplayText(String role) {
    return role.substring(0, 1).toUpperCase() + role.substring(1);
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
