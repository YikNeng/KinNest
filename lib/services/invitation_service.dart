import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send invitation to join a group
  Future<void> sendInvitation({
    required String groupId,
    required String email,
    required String role,
    required String invitedBy,
  }) async {
    try {
      // Check if email is already invited or member
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;

      // Check if already invited
      List<dynamic> invitations = groupData['invitations'] ?? [];
      bool alreadyInvited = invitations.any(
        (inv) =>
            inv['email'].toString().toLowerCase() == email.toLowerCase() &&
            inv['status'] == 'pending',
      );

      if (alreadyInvited) {
        throw Exception('This email already has a pending invitation');
      }

      // Check if user with this email already exists and is a member
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String existingUserId = userSnapshot.docs.first.id;
        List<dynamic> memberIds = groupData['memberIds'] ?? [];
        String adminId = groupData['adminId'];

        // Check if already a member
        if (memberIds.contains(existingUserId) || adminId == existingUserId) {
          throw Exception('This user is already a member of the group');
        }
      }

      // Add invitation to group document
      await _firestore.collection('groups').doc(groupId).update({
        'invitations': FieldValue.arrayUnion([
          {
            'email': email.toLowerCase(),
            'role': role,
            'invitedBy': invitedBy,
            'invitedAt': Timestamp.now(),
            'status': 'pending',
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to send invitation: $e');
    }
  }

  /// Get all pending invitations for a group
  Future<List<Map<String, dynamic>>> getGroupInvitations(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return [];
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> invitations = groupData['invitations'] ?? [];

      // Convert to List<Map<String, dynamic>>
      return invitations.map((inv) => Map<String, dynamic>.from(inv)).toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  /// Get pending invitations for a specific email
  Future<List<Map<String, dynamic>>> getPendingInvitationsForEmail(
    String email,
  ) async {
    try {
      // Query all groups that have invitations for this email
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('invitations', isNotEqualTo: [])
          .get();

      List<Map<String, dynamic>> pendingInvitations = [];

      for (var doc in groupsSnapshot.docs) {
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        List<dynamic> invitations = groupData['invitations'] ?? [];

        // Find invitations for this email with pending status
        for (var inv in invitations) {
          if (inv['email'].toString().toLowerCase() == email.toLowerCase() &&
              inv['status'] == 'pending') {
            pendingInvitations.add({
              'groupId': doc.id,
              'groupName': groupData['groupName'],
              'email': inv['email'],
              'role': inv['role'],
              'invitedAt': inv['invitedAt'],
            });
          }
        }
      }

      return pendingInvitations;
    } catch (e) {
      throw Exception('Failed to get pending invitations: $e');
    }
  }

  /// Get pending invitations for current user's email
  Future<List<Map<String, dynamic>>> getPendingInvitationsForCurrentUser(
    String userEmail,
  ) async {
    try {
      // Query all groups that have invitations
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('invitations', isNotEqualTo: [])
          .get();

      List<Map<String, dynamic>> pendingInvitations = [];

      for (var doc in groupsSnapshot.docs) {
        Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
        String groupId = doc.id;
        String groupName = groupData['groupName'] ?? 'Unknown Group';
        String adminId = groupData['adminId'];
        List<dynamic> invitations = groupData['invitations'] ?? [];

        // Find pending invitations for this user's email
        for (var inv in invitations) {
          if (inv['email'].toString().toLowerCase() ==
                  userEmail.toLowerCase() &&
              inv['status'] == 'pending') {
            // Fetch inviter details
            String inviterName = 'Unknown';
            try {
              DocumentSnapshot inviterDoc = await _firestore
                  .collection('users')
                  .doc(inv['invitedBy'])
                  .get();
              if (inviterDoc.exists) {
                Map<String, dynamic> inviterData =
                    inviterDoc.data() as Map<String, dynamic>;
                inviterName = inviterData['name'] ?? 'Unknown';
              }
            } catch (e) {
              // Ignore errors and keep inviterName as 'Unknown'
            }

            pendingInvitations.add({
              'groupId': groupId,
              'groupName': groupName,
              'adminId': adminId,
              'email': inv['email'],
              'role': inv['role'],
              'invitedBy': inv['invitedBy'],
              'inviterName': inviterName,
              'invitedAt': inv['invitedAt'],
              'invitation': inv,
            });
          }
        }
      }

      // Sort by invitation date
      pendingInvitations.sort((a, b) {
        Timestamp aTime = a['invitedAt'] ?? Timestamp.now();
        Timestamp bTime = b['invitedAt'] ?? Timestamp.now();
        return bTime.compareTo(aTime);
      });

      return pendingInvitations;
    } catch (e) {
      throw Exception('Failed to get pending invitations: $e');
    }
  }

  /// Accept invitation and join group
  Future<void> acceptInvitation({
    required String groupId,
    required String userEmail,
    required String userId,
    required String role,
  }) async {
    try {
      //  Get group document
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> invitations = groupData['invitations'] ?? [];

      // Find the pending invitation
      Map<String, dynamic>? targetInvitation;
      int invitationIndex = -1;

      for (int i = 0; i < invitations.length; i++) {
        var inv = invitations[i];
        if (inv['email'].toString().toLowerCase() == userEmail.toLowerCase() &&
            inv['status'] == 'pending') {
          targetInvitation = Map<String, dynamic>.from(inv);
          invitationIndex = i;
          break;
        }
      }

      if (targetInvitation == null) {
        throw Exception('Invitation not found or already processed');
      }

      // Check if user is already a member
      String adminId = groupData['adminId'];
      List<dynamic> memberIds = groupData['memberIds'] ?? [];

      if (adminId == userId || memberIds.contains(userId)) {
        throw Exception('You are already a member of this group');
      }

      // Update invitation status to "accepted"
      targetInvitation['status'] = 'accepted';
      targetInvitation['acceptedAt'] = Timestamp.now();
      targetInvitation['acceptedBy'] = userId;

      // Update the invitation in the array
      invitations[invitationIndex] = targetInvitation;

      // Prepare batch write
      WriteBatch batch = _firestore.batch();

      // Update group document
      DocumentReference groupRef = _firestore.collection('groups').doc(groupId);

      // Update invitations array
      batch.update(groupRef, {
        'invitations': invitations,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Update user's groupIds
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'groupIds': FieldValue.arrayUnion([groupId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Reject invitation
  Future<void> rejectInvitation({
    required String groupId,
    required String userEmail,
    required String userId,
  }) async {
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
      List<dynamic> invitations = groupData['invitations'] ?? [];

      // Find the pending invitation
      Map<String, dynamic>? targetInvitation;
      int invitationIndex = -1;

      for (int i = 0; i < invitations.length; i++) {
        var inv = invitations[i];
        if (inv['email'].toString().toLowerCase() == userEmail.toLowerCase() &&
            inv['status'] == 'pending') {
          targetInvitation = Map<String, dynamic>.from(inv);
          invitationIndex = i;
          break;
        }
      }

      if (targetInvitation == null) {
        throw Exception('Invitation not found or already processed');
      }

      // Update invitation status to "rejected"
      targetInvitation['status'] = 'rejected';
      targetInvitation['rejectedAt'] = Timestamp.now();
      targetInvitation['rejectedBy'] = userId;

      // Update the invitation in the array
      invitations[invitationIndex] = targetInvitation;

      // Update group document
      await _firestore.collection('groups').doc(groupId).update({
        'invitations': invitations,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to reject invitation: $e');
    }
  }

  /// Format invitation date
  String formatInvitationDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    }
  }

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address';
    }

    final email = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}
