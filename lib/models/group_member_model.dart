import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing a group member
class GroupMemberModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'caregiver' or 'elderly'
  final bool isAdmin;
  final DateTime? joinedAt;

  GroupMemberModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
    this.joinedAt,
  });

  /// Create from Firestore document
  factory GroupMemberModel.fromMap(Map<String, dynamic> map, String uid) {
    return GroupMemberModel(
      uid: uid,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      role: map['role'] ?? 'elderly',
      isAdmin: map['isAdmin'] ?? false,
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Get role display label
  String get roleLabel {
    if (isAdmin) return 'Admin';
    return role == 'caregiver' ? 'Caregiver' : 'Elderly';
  }

  /// Get role color
  Color get roleColor {
    if (isAdmin) return Colors.blue;
    return role == 'caregiver' ? Colors.green : Colors.orange;
  }

  /// Get role icon
  IconData get roleIcon {
    if (isAdmin) return Icons.admin_panel_settings;
    return role == 'caregiver' ? Icons.medical_services : Icons.elderly;
  }
}
