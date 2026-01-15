import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GroupService _groupService = GroupService();

  /// Generic method to add a notification to Firestore
  Future<void> _sendNotification({
    required List<String> recipientIds,
    required String title,
    required String body,
    required String type, // 'reminder_created', 'reminder_update', 'overdue'
    required String relatedId, // groupId or reminderId
    Map<String, dynamic>? extraData,
  }) async {
    if (recipientIds.isEmpty) return;

    final batch = _firestore.batch();

    // Remove duplicates and current user
    final currentUserId = _auth.currentUser?.uid;
    final uniqueRecipients = recipientIds.toSet()..remove(currentUserId);

    for (String userId in uniqueRecipients) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

      batch.set(docRef, {
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      });
    }

    await batch.commit();
  }

  /// 1. Notify Elderly: Caregiver creates reminder for them
  Future<void> notifyElderlyOfNewReminder(
    String elderlyId,
    String reminderTitle,
    String caregiverName,
  ) async {
    await _sendNotification(
      recipientIds: [elderlyId],
      title: 'New Reminder',
      body: '$caregiverName added a reminder: $reminderTitle',
      type: 'reminder_created',
      relatedId: '',
    );
    print('Notified elderly user: $elderlyId');
  }

  /// 2. Notify Caregivers: Elderly creates reminder for themselves
  Future<void> notifyCaregiversOfAction(
    String groupId,
    String elderlyName,
    String actionText,
  ) async {
    try {
      // Fetch group details to find admins/caregivers
      Map<String, dynamic>? groupData = await _groupService.getGroupDetails(
        groupId,
      );
      if (groupData == null) return;

      List<dynamic> members = groupData['members'] ?? [];

      // Filter for caregivers/admins
      List<String> caregiverIds = members
          .where((m) => m['role'] == 'caregiver' || m['isAdmin'] == true)
          .map((m) => m['uid'] as String)
          .toList();

      await _sendNotification(
        recipientIds: caregiverIds,
        title: 'Activity Alert',
        body: '$elderlyName $actionText', // e.g., "created a reminder"
        type: 'reminder_activity',
        relatedId: groupId,
      );
      print('Notified caregivers: $caregiverIds');
    } catch (e) {
      print('Failed to notify caregivers: $e');
    }
  }

  /// 3. Notify Group: Anyone edits/deletes a reminder
  Future<void> notifyGroupOfChanges(
    String groupId,
    String userName,
    String changeDescription,
  ) async {
    try {
      Map<String, dynamic>? groupData = await _groupService.getGroupDetails(
        groupId,
      );
      if (groupData == null) return;

      List<dynamic> members = groupData['members'] ?? [];
      List<String> memberIds = members.map((m) => m['uid'] as String).toList();

      await _sendNotification(
        recipientIds: memberIds,
        title: 'Reminder Updated',
        body: '$userName $changeDescription',
        type: 'reminder_update',
        relatedId: groupId,
      );
      print('Notified group members: $memberIds');
    } catch (e) {
      print('Failed to notify group: $e');
    }
  }

  /// 4. Notify Caregivers: Elderly completes a reminder
  Future<void> notifyCaregiversOfCompletion(
    String groupId,
    String elderlyName,
    String reminderTitle,
  ) async {
    try {
      Map<String, dynamic>? groupData = await _groupService.getGroupDetails(
        groupId,
      );
      if (groupData == null) return;

      List<dynamic> members = groupData['members'] ?? [];

      // Filter for caregivers/admins
      List<String> caregiverIds = members
          .where((m) => m['role'] == 'caregiver' || m['isAdmin'] == true)
          .map((m) => m['uid'] as String)
          .toList();

      await _sendNotification(
        recipientIds: caregiverIds,
        title: 'Task Completed',
        body: '$elderlyName completed: $reminderTitle',
        type: 'reminder_completed',
        relatedId: groupId,
      );
    } catch (e) {
      print('Failed to notify completion: $e');
    }
  }

  /// 5. Notify Caregivers: Reminder becomes overdue (alarm timeout)
  /// This is called when the alarm times out after 2 minutes without user action
  Future<void> notifyCaregiversOfOverdue(
    String groupId,
    String elderlyName,
    String reminderTitle,
  ) async {
    try {
      Map<String, dynamic>? groupData = await _groupService.getGroupDetails(
        groupId,
      );
      if (groupData == null) return;

      List<dynamic> members = groupData['members'] ?? [];

      // Filter for caregivers/admins
      List<String> caregiverIds = members
          .where((m) => m['role'] == 'caregiver' || m['isAdmin'] == true)
          .map((m) => m['uid'] as String)
          .toList();

      await _sendNotification(
        recipientIds: caregiverIds,
        title: '⚠️ Overdue Reminder',
        body: '$elderlyName did not respond to: $reminderTitle',
        type: 'reminder_overdue',
        relatedId: groupId,
        extraData: {
          'priority': 'high',
          'elderlyName': elderlyName,
          'reminderTitle': reminderTitle,
        },
      );
      print('Notified caregivers of overdue: $caregiverIds');
    } catch (e) {
      print('Failed to notify overdue: $e');
    }
  }
}
