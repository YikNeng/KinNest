import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latest_fyp/models/group_member_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all groups where user is admin or member
  Stream<List<Map<String, dynamic>>> getUserGroupsStream(String userId) {
    return _firestore
        .collection('groups')
        .where('adminId', isEqualTo: userId) // Groups where user is admin
        .snapshots()
        .asyncMap((adminSnapshot) async {
          // Get groups where user is admin
          List<Map<String, dynamic>> groups = adminSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['groupId'] = doc.id; // Include document ID
            return data;
          }).toList();

          // get groups where user is a member
          QuerySnapshot memberSnapshot = await _firestore
              .collection('groups')
              .where('memberIds', arrayContains: userId)
              .get();

          for (var doc in memberSnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String adminId = data['adminId'] as String;

            // Only add if user is not admin
            if (adminId != userId) {
              data['groupId'] = doc.id;
              groups.add(data);
            }
          }

          return groups;
        });
  }

  /// Get all groups where user is admin or member
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      List<Map<String, dynamic>> groups = [];

      // Get groups where user is admin
      QuerySnapshot adminSnapshot = await _firestore
          .collection('groups')
          .where('adminId', isEqualTo: userId)
          .get();

      for (var doc in adminSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['groupId'] = doc.id;
        groups.add(data);
      }

      // Get groups where user is a member
      QuerySnapshot memberSnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      for (var doc in memberSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String adminId = data['adminId'] as String;

        // Only add if user is not admin
        if (adminId != userId) {
          data['groupId'] = doc.id;
          groups.add(data);
        }
      }

      return groups;
    } catch (e) {
      throw Exception('Failed to fetch groups: $e');
    }
  }

  /// Create a new group
  Future<String> createGroup({
    required String groupName,
    required String adminId,
    String? description,
  }) async {
    try {
      // Create group document in Firestore
      DocumentReference groupRef = await _firestore.collection('groups').add({
        'groupName': groupName.trim(),
        'description': description?.trim(),
        'adminId': adminId,
        'memberIds': [],
        'invitations': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update creator's groupIds array in users collection
      await _firestore.collection('users').doc(adminId).update({
        'groupIds': FieldValue.arrayUnion([groupRef.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return groupRef.id;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Update group information (admin only)
  Future<void> updateGroup({
    required String groupId,
    required String groupName,
    String? description,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'groupName': groupName,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  /// Delete group and all related data (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      // Get group data
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      String adminId = groupData['adminId'];
      List<dynamic> memberIds = groupData['memberIds'] ?? [];

      // Delete all reminders associated with this group
      QuerySnapshot remindersSnapshot = await _firestore
          .collection('reminders')
          .where('groupId', isEqualTo: groupId)
          .get();

      WriteBatch batch = _firestore.batch();

      // Delete reminders
      for (var reminderDoc in remindersSnapshot.docs) {
        batch.delete(reminderDoc.reference);
      }

      // Remove group from admin's groupIds
      DocumentReference adminRef = _firestore.collection('users').doc(adminId);
      batch.update(adminRef, {
        'groupIds': FieldValue.arrayRemove([groupId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove group from all members' groupIds
      for (String memberId in memberIds) {
        DocumentReference memberRef = _firestore
            .collection('users')
            .doc(memberId);
        batch.update(memberRef, {
          'groupIds': FieldValue.arrayRemove([groupId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Delete the group document itself
      batch.delete(_firestore.collection('groups').doc(groupId));

      // Commit all changes atomically
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Get group member count
  Future<int> getGroupMemberCount(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return 0;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> memberIds = groupData['memberIds'] ?? [];

      return 1 + memberIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get reminder count for group
  Future<int> getGroupReminderCount(String groupId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('groupId', isEqualTo: groupId)
          .where('isCompleted', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Validate group name
  String? validateGroupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a group name';
    }
    if (value.trim().length < 3) {
      return 'Group name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Group name must be less than 50 characters';
    }
    return null;
  }

  /// Validate group description
  String? validateGroupDescription(String? value) {
    if (value != null && value.trim().length > 200) {
      return 'Description must be less than 200 characters';
    }
    return null;
  }

  /// Get single group by ID
  Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['groupId'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch group: $e');
    }
  }

  /// Check if user is admin of a group
  Future<bool> isUserGroupAdmin(String userId, String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return false;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      return groupData['adminId'] == userId;
    } catch (e) {
      return false;
    }
  }

  /// Get group data by ID
  bool isAdmin(String userId, Map<String, dynamic> groupData) {
    return groupData['adminId'] == userId;
  }

  /// Get member count
  int getMemberCount(Map<String, dynamic> groupData) {
    List<dynamic> memberIds = groupData['memberIds'] ?? [];
    return memberIds.length + 1; // Including admin
  }

  /// Get detailed group information including members
  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return null;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      groupData['groupId'] = groupDoc.id;

      // Fetch member details
      List<Map<String, dynamic>> members = [];

      // Add admin details
      String adminId = groupData['adminId'];
      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .get();
      if (adminDoc.exists) {
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;
        adminData['isAdmin'] = true;
        members.add(adminData);
      }

      // Add elderly members
      List<dynamic> memberIds = groupData['memberIds'] ?? [];
      for (String memberId in memberIds) {
        DocumentSnapshot memberDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();
        if (memberDoc.exists) {
          Map<String, dynamic> memberData =
              memberDoc.data() as Map<String, dynamic>;
          memberData['isAdmin'] = false;
          members.add(memberData);
        }
      }

      groupData['members'] = members;
      return groupData;
    } catch (e) {
      throw Exception('Failed to fetch group details: $e');
    }
  }

  /// Get group details as a stream
  Stream<Map<String, dynamic>?> getGroupDetailsStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().asyncMap((
      groupSnapshot,
    ) async {
      if (!groupSnapshot.exists) {
        return null;
      }

      Map<String, dynamic> groupData =
          groupSnapshot.data() as Map<String, dynamic>;
      groupData['groupId'] = groupSnapshot.id;

      // Fetch member details
      List<Map<String, dynamic>> members = [];

      // Add admin
      String adminId = groupData['adminId'];
      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .get();
      if (adminDoc.exists) {
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;
        adminData['isAdmin'] = true;
        members.add(adminData);
      }

      // Add elderly members
      List<dynamic> memberIds = groupData['memberIds'] ?? [];
      for (String memberId in memberIds) {
        DocumentSnapshot memberDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();
        if (memberDoc.exists) {
          Map<String, dynamic> memberData =
              memberDoc.data() as Map<String, dynamic>;
          memberData['isAdmin'] = false;
          members.add(memberData);
        }
      }

      groupData['members'] = members;
      return groupData;
    });
  }

  /// Get pending invitations for a group
  List<Map<String, dynamic>> getGroupInvitations(
    Map<String, dynamic> groupData,
  ) {
    List<dynamic> invitations = groupData['invitations'] ?? [];
    return invitations
        .where((inv) => inv['status'] == 'pending')
        .map((inv) => Map<String, dynamic>.from(inv))
        .toList();
  }

  /// Check if user is member of the group
  bool isMember(String userId, Map<String, dynamic> groupData) {
    String adminId = groupData['adminId'];
    List<dynamic> memberIds = groupData['memberIds'] ?? [];
    return adminId == userId || memberIds.contains(userId);
  }

  /// Get all members in a group with their details
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      // Get group document
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      String adminId = groupData['adminId'];
      List<dynamic> memberIds = groupData['memberIds'] ?? [];

      List<GroupMemberModel> members = [];

      // Fetch admin details
      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .get();

      if (adminDoc.exists) {
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;
        members.add(
          GroupMemberModel(
            uid: adminId,
            name: adminData['name'] ?? 'Unknown',
            email: adminData['email'] ?? '',
            role: adminData['role'] ?? 'caregiver',
            isAdmin: true,
            joinedAt: groupData['createdAt'] != null
                ? (groupData['createdAt'] as Timestamp).toDate()
                : null,
          ),
        );
      }

      // Fetch member details
      for (String memberId in memberIds) {
        if (memberId == adminId) continue;

        DocumentSnapshot memberDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();

        if (memberDoc.exists) {
          Map<String, dynamic> memberData =
              memberDoc.data() as Map<String, dynamic>;
          members.add(
            GroupMemberModel(
              uid: memberId,
              name: memberData['name'] ?? 'Unknown',
              email: memberData['email'] ?? '',
              role: memberData['role'] ?? 'elderly',
              isAdmin: false,
              joinedAt: null,
            ),
          );
        }
      }

      return members;
    } catch (e) {
      throw Exception('Failed to fetch group members: $e');
    }
  }

  /// Remove a member from the group
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      // Get group document
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      String adminId = groupData['adminId'];

      // Prevent admin from removing themselves
      if (userId == adminId) {
        throw Exception('Admin cannot remove themselves from the group');
      }

      // Remove user from memberIds array
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Check if user is admin of a group
  Future<bool> isGroupAdmin(String groupId, String userId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return false;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      return groupData['adminId'] == userId;
    } catch (e) {
      return false;
    }
  }
}
