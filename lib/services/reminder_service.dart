import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Get all reminders for a group (stream for real-time updates)
  Stream<List<Map<String, dynamic>>> getGroupRemindersStream(String groupId) {
    return _firestore
        .collection('reminders')
        .where('groupId', isEqualTo: groupId)
        .orderBy('scheduledTime', descending: false) // Earliest first
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['reminderId'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Get all reminders for a group (one-time fetch)
  Future<List<Map<String, dynamic>>> getGroupReminders(String groupId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('groupId', isEqualTo: groupId)
          .orderBy('scheduledTime', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['reminderId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  /// Get upcoming reminders for a group (next 5)
  Future<List<Map<String, dynamic>>> getGroupUpcomingReminders(
    String groupId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('groupId', isEqualTo: groupId)
          .where(
            'scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.now(),
          ) // Future reminders only
          .orderBy('scheduledTime', descending: false) // Earliest first
          .limit(5) // Only show next 5
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['reminderId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  /// Mark reminder as completed with history tracking
  Future<void> markReminderCompleteWithHistory(
    String reminderId,
    String userId,
  ) async {
    try {
      DocumentSnapshot reminderDoc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (!reminderDoc.exists) {
        throw Exception('Reminder not found');
      }

      Map<String, dynamic> reminderData =
          reminderDoc.data() as Map<String, dynamic>;

      // Get existing completion history
      List<dynamic> completionHistory = reminderData['completionHistory'] ?? [];

      // Add new completion record
      Map<String, dynamic> newCompletion = {
        'completedAt': Timestamp.now(),
        'completedBy': userId,
      };

      completionHistory.add(newCompletion);

      // Check repeat type
      String repeatType = reminderData['repeatType'] ?? 'once';
      bool isRecurring = repeatType != 'once';

      // Update reminder base data
      Map<String, dynamic> updateData = {
        'isCompleted': true,
        'completedAt': Timestamp.now(),
        'completedBy': userId,
        'completionHistory': completionHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If recurring, schedule next occurrence
      if (isRecurring) {
        Timestamp currentScheduledTimestamp = reminderData['scheduledTime'];
        DateTime currentScheduledTime = currentScheduledTimestamp.toDate();

        // Get repeatDays if available (for specific_days type)
        List<int> repeatDays = [];
        if (reminderData['repeatDays'] != null) {
          repeatDays = List<int>.from(reminderData['repeatDays']);
        }

        DateTime nextScheduledTime = _calculateNextOccurrence(
          currentScheduledTime,
          repeatType,
          repeatDays, // Pass the specific days
        );

        updateData['scheduledTime'] = Timestamp.fromDate(nextScheduledTime);
        updateData['isCompleted'] = false; // Reset for next occurrence
        updateData['isOverdueNotified'] = false;
        updateData['completedAt'] =
            Timestamp.now(); // Keep last completion timestamp reference
      }

      await _firestore
          .collection('reminders')
          .doc(reminderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to mark reminder as complete: $e');
    }
  }

  /// Calculate next occurrence for recurring reminders
  DateTime _calculateNextOccurrence(
    DateTime currentTime,
    String repeatType, [
    List<int>? repeatDays,
  ]) {
    if (repeatType == 'specific_days' &&
        repeatDays != null &&
        repeatDays.isNotEmpty) {
      // Find the next matching day of the week
      // 1 = Mon, 7 = Sun

      // Sort days to be safe
      repeatDays.sort();

      int currentWeekday = currentTime.weekday;

      // Look for a day later in the current week
      for (int day in repeatDays) {
        if (day > currentWeekday) {
          int daysToAdd = day - currentWeekday;
          return currentTime.add(Duration(days: daysToAdd));
        }
      }

      // If no day found later this week, wrap to the first available day next week
      int firstDayNextWeek = repeatDays.first;
      int daysUntilEndOfWeek = 7 - currentWeekday;
      int daysToAdd = daysUntilEndOfWeek + firstDayNextWeek;

      return currentTime.add(Duration(days: daysToAdd));
    }

    // Legacy/Standard repeat types
    switch (repeatType.toLowerCase()) {
      case 'daily':
        return currentTime.add(const Duration(days: 1));
      case 'weekly':
        return currentTime.add(const Duration(days: 7));
      case 'monthly':
        int year = currentTime.year;
        int month = currentTime.month + 1;
        if (month > 12) {
          year++;
          month = 1;
        }
        return DateTime(
          year,
          month,
          currentTime.day,
          currentTime.hour,
          currentTime.minute,
        );
      case 'every_2_days':
        return currentTime.add(const Duration(days: 2));
      case 'every_3_days':
        return currentTime.add(const Duration(days: 3));
      case 'every_4_days':
        return currentTime.add(const Duration(days: 4));
      case 'every_5_days':
        return currentTime.add(const Duration(days: 5));
      case 'every_6_days':
        return currentTime.add(const Duration(days: 6));
      default:
        // Fallback for 'once' or unknown
        return currentTime.add(const Duration(days: 1));
    }
  }

  /// Mark reminder as incomplete (undo completion)
  Future<void> markReminderIncompleteWithHistory(String reminderId) async {
    try {
      // For recurring reminders, we don't undo - just let next cycle handle it
      // For one-time reminders, we can undo
      DocumentSnapshot reminderDoc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (!reminderDoc.exists) {
        throw Exception('Reminder not found');
      }

      Map<String, dynamic> reminderData =
          reminderDoc.data() as Map<String, dynamic>;
      String repeatType = reminderData['repeatType'] ?? 'once';

      if (repeatType != 'once') {
        throw Exception('Cannot undo completion for recurring reminders');
      }

      await _firestore.collection('reminders').doc(reminderId).update({
        'isCompleted': false,
        'completedAt': null,
        'completedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
        // Note: We keep completionHistory for audit trail
      });
    } catch (e) {
      throw Exception('Failed to mark reminder as incomplete: $e');
    }
  }

  /// Get completion history for a reminder
  List<Map<String, dynamic>> getCompletionHistory(
    Map<String, dynamic> reminder,
  ) {
    List<dynamic> history = reminder['completionHistory'] ?? [];
    return history.map((h) => Map<String, dynamic>.from(h)).toList();
  }

  /// Get completion count
  int getCompletionCount(Map<String, dynamic> reminder) {
    List<dynamic> history = reminder['completionHistory'] ?? [];
    return history.length;
  }

  /// Get last completion date
  DateTime? getLastCompletionDate(Map<String, dynamic> reminder) {
    List<dynamic> history = reminder['completionHistory'] ?? [];
    if (history.isEmpty) return null;

    // Get most recent completion
    Map<String, dynamic> lastCompletion = history.last;
    Timestamp completedAt = lastCompletion['completedAt'];
    return completedAt.toDate();
  }

  /// Format completion history date
  String formatCompletionDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes < 5) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  /// Check if reminder is recurring
  bool isRecurringReminder(Map<String, dynamic> reminder) {
    String repeatType = reminder['repeatType'] ?? 'once';
    return repeatType != 'once';
  }

  /// Get next occurrence date for recurring reminder
  DateTime? getNextOccurrence(Map<String, dynamic> reminder) {
    if (!isRecurringReminder(reminder)) return null;

    Timestamp scheduledTime = reminder['scheduledTime'];
    return scheduledTime.toDate();
  }

  /// Calculate completion rate (for recurring reminders)
  double getCompletionRate(Map<String, dynamic> reminder) {
    if (!isRecurringReminder(reminder)) {
      return reminder['isCompleted'] == true ? 1.0 : 0.0;
    }

    // For recurring, calculate based on expected occurrences
    Timestamp createdAt = reminder['createdAt'];
    DateTime createdDate = createdAt.toDate();
    DateTime now = DateTime.now();

    String repeatType = reminder['repeatType'] ?? 'daily';
    int expectedOccurrences = _calculateExpectedOccurrences(
      createdDate,
      now,
      repeatType,
    );

    int actualCompletions = getCompletionCount(reminder);

    if (expectedOccurrences == 0) return 0.0;
    return (actualCompletions / expectedOccurrences).clamp(0.0, 1.0);
  }

  /// Calculate expected occurrences
  int _calculateExpectedOccurrences(
    DateTime startDate,
    DateTime endDate,
    String repeatType,
  ) {
    Duration difference = endDate.difference(startDate);
    int days = difference.inDays;

    switch (repeatType) {
      case 'daily':
        return days;
      case 'weekly':
        return (days / 7).floor();
      case 'monthly':
        return (days / 30).floor();
      case 'every_2_days':
        return (days / 2).floor();
      case 'every_3_days':
        return (days / 3).floor();
      case 'every_4_days':
        return (days / 4).floor();
      case 'every_5_days':
        return (days / 5).floor();
      case 'every_6_days':
        return (days / 6).floor();
      default:
        return 1;
    }
  }

  /// Delete reminder (caregiver only)
  // In lib/services/reminder_service.dart

  Future<void> deleteReminder(String reminderId) async {
    try {
      // 1. FETCH FIRST (Move this up)
      DocumentSnapshot doc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 2. DELETE SECOND
        await _firestore.collection('reminders').doc(reminderId).delete();

        // 3. NOTIFY
        String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        Map<String, dynamic>? user = await getUserDetails(currentUserId);

        await _notificationService.notifyGroupOfChanges(
          data['groupId'],
          user?['name'] ?? 'A member',
          'deleted the reminder: ${data['title']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  /// Format timestamp to readable string
  String formatReminderTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime reminderDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    // Calculate difference in days
    int daysDifference = reminderDate.difference(today).inDays;

    String timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (daysDifference == 0) {
      return 'Today at $timeString';
    } else if (daysDifference == 1) {
      return 'Tomorrow at $timeString';
    } else if (daysDifference == -1) {
      return 'Yesterday at $timeString';
    } else if (daysDifference < 7 && daysDifference > 0) {
      List<String> weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return '${weekdays[dateTime.weekday - 1]} at $timeString';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $timeString';
    }
  }

  /// Check if reminder is overdue
  bool isOverdue(Map<String, dynamic> reminder) {
    if (reminder['isCompleted'] == true) {
      return false; // Completed reminders are never overdue
    }

    Timestamp scheduledTime = reminder['scheduledTime'];
    DateTime scheduledDateTime = scheduledTime.toDate();
    return scheduledDateTime.isBefore(DateTime.now());
  }

  /// Get reminder type icon
  /// FIXED: Replaced corrupted characters with standard Emojis
  String getReminderTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'medication':
        return '💊';
      case 'appointment':
        return '📅';
      default:
        return '🔔';
    }
  }

  /// Get reminder type color
  /// FIXED: Replaced corrupted characters
  String getReminderTypeColorName(String? type) {
    switch (type?.toLowerCase()) {
      case 'medication':
        return 'red';
      case 'appointment':
        return 'blue';
      default:
        return 'grey';
    }
  }

  /// Create a new reminder
  Future<String> createReminder({
    required String groupId,
    required String createdBy,
    required String assignedTo,
    required String title,
    String? description,
    required String type,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String repeatType,
    List<int>? repeatDays, // Added parameter
    String? voiceNoteUrl,
    Map<String, dynamic>? typeSpecificData,
  }) async {
    try {
      List<String> timeParts = scheduledTime.split(':');
      DateTime scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      Map<String, dynamic> reminderData = {
        'groupId': groupId,
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'title': title,
        'description': description,
        'type': type,
        'scheduledTime': Timestamp.fromDate(scheduledDateTime),
        'repeatType': repeatType,
        'voiceNoteUrl': voiceNoteUrl,
        'isCompleted': false,
        'isOverdueNotified': false,
        'completedAt': null,
        'completedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add repeatDays if specific_days
      if (repeatType == 'specific_days' && repeatDays != null) {
        reminderData['repeatDays'] = repeatDays;
      }

      if (typeSpecificData != null) {
        reminderData['typeSpecificData'] = typeSpecificData;
      }

      // Inside createReminder method...

      DocumentReference docRef = await _firestore
          .collection('reminders')
          .add(reminderData);

      // --- ADD THIS BLOCK ---
      try {
        // Get creator details to know who is sending it
        Map<String, dynamic>? creator = await getUserDetails(createdBy);
        String creatorName = creator?['name'] ?? 'A caregiver';
        String creatorRole = creator?['role'] ?? 'unknown';

        // Case A: Caregiver creates for Elderly
        if (creatorRole == 'caregiver' && createdBy != assignedTo) {
          await _notificationService.notifyElderlyOfNewReminder(
            assignedTo, // The elderly ID
            title,
            creatorName,
          );
        }
        // Case B: Elderly creates for themselves
        else if (creatorRole == 'elderly') {
          await _notificationService.notifyCaregiversOfAction(
            groupId,
            creatorName,
            'created a new reminder: $title',
          );
        }
      } catch (e) {
        print("Notification Error: $e"); // Log error but don't stop the app
      }
      // --- END BLOCK ---

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  /// Update existing reminder
  Future<void> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required String type,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String repeatType,
    List<int>? repeatDays, // Added parameter
    String? voiceNoteUrl,
    Map<String, dynamic>? typeSpecificData,
  }) async {
    try {
      List<String> timeParts = scheduledTime.split(':');
      DateTime scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'type': type,
        'scheduledTime': Timestamp.fromDate(scheduledDateTime),
        'repeatType': repeatType,
        'voiceNoteUrl': voiceNoteUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'isOverdueNotified': false,
      };

      // Handle repeatDays update
      if (repeatType == 'specific_days' && repeatDays != null) {
        updateData['repeatDays'] = repeatDays;
      } else {
        // Remove repeatDays if switching to a non-specific type
        updateData['repeatDays'] = FieldValue.delete();
      }

      if (typeSpecificData != null) {
        updateData['typeSpecificData'] = typeSpecificData;
      }

      await _firestore
          .collection('reminders')
          .doc(reminderId)
          .update(updateData);
      // Fetch reminder to get groupId for notification
      DocumentSnapshot oldDoc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();
      if (oldDoc.exists) {
        Map<String, dynamic> data = oldDoc.data() as Map<String, dynamic>;
        String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        Map<String, dynamic>? user = await getUserDetails(currentUserId);

        await _notificationService.notifyGroupOfChanges(
          data['groupId'],
          user?['name'] ?? 'A member',
          'updated the reminder: $title',
        );
      }
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Get single reminder by ID
  Future<Map<String, dynamic>?> getReminderById(String reminderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['reminderId'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch reminder: $e');
    }
  }

  /// Validate reminder fields
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  /// Format reminder type display name
  String getReminderTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return 'Medication';
      case 'appointment':
        return 'Appointment';
      case 'normal':
      default:
        return 'Reminder';
    }
  }

  /// Get user details by ID
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return {
        'uid': userId,
        'name': userData['name'] ?? 'Unknown',
        'email': userData['email'] ?? '',
        'role': userData['role'] ?? 'elderly',
      };
    } catch (e) {
      return null;
    }
  }

  /// Get multiple users at once (batch fetch for efficiency)
  Future<Map<String, Map<String, dynamic>>> getUsersBatch(
    List<String> userIds,
  ) async {
    Map<String, Map<String, dynamic>> usersMap = {};

    if (userIds.isEmpty) return usersMap;

    try {
      // Firestore 'in' query supports up to 10 items
      // If more than 10, split into multiple queries
      List<List<String>> chunks = [];
      for (int i = 0; i < userIds.length; i += 10) {
        chunks.add(
          userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10),
        );
      }

      for (List<String> chunk in chunks) {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          usersMap[doc.id] = {
            'uid': doc.id,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'role': userData['role'] ?? 'elderly',
          };
        }
      }

      return usersMap;
    } catch (e) {
      return usersMap;
    }
  }

  /// Format user display name
  String formatUserDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'Unknown User';

    String name = user['name'] ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    // Fallback to email
    String email = user['email'] ?? '';
    if (email.isNotEmpty) {
      return email;
    }

    return 'Unknown User';
  }

  /// Get initials from name for avatar
  String getUserInitials(Map<String, dynamic>? user) {
    if (user == null) return '?';

    String name = user['name'] ?? '';
    if (name.isEmpty) return '?';

    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '?';
  }

  /// Get nearest upcoming reminder across all groups caregiver manages
  Future<Map<String, dynamic>?> getNearestUpcomingReminder(
    String caregiverId,
  ) async {
    try {
      // Step 1: Get all groups where caregiver is admin
      QuerySnapshot adminGroupsSnapshot = await _firestore
          .collection('groups')
          .where('adminId', isEqualTo: caregiverId)
          .get();

      List<String> groupIds = adminGroupsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      if (groupIds.isEmpty) {
        return null;
      }

      // Step 2: Get all upcoming reminders from these groups
      DateTime now = DateTime.now();
      Timestamp nowTimestamp = Timestamp.fromDate(now);

      List<Map<String, dynamic>> upcomingReminders = [];

      // Firestore 'in' query supports max 10 items, so chunk if needed
      for (int i = 0; i < groupIds.length; i += 10) {
        List<String> chunk = groupIds.sublist(
          i,
          i + 10 > groupIds.length ? groupIds.length : i + 10,
        );

        QuerySnapshot remindersSnapshot = await _firestore
            .collection('reminders')
            .where('groupId', whereIn: chunk)
            .where('scheduledTime', isGreaterThanOrEqualTo: nowTimestamp)
            .orderBy('scheduledTime', descending: false)
            .limit(50) // Get first 50 to sort in memory
            .get();

        for (var doc in remindersSnapshot.docs) {
          Map<String, dynamic> reminderData =
              doc.data() as Map<String, dynamic>;
          reminderData['reminderId'] = doc.id;

          // Only include if not completed (or if recurring)
          bool isCompleted = reminderData['isCompleted'] ?? false;
          String repeatType = reminderData['repeatType'] ?? 'once';

          if (!isCompleted || repeatType != 'once') {
            upcomingReminders.add(reminderData);
          }
        }
      }

      if (upcomingReminders.isEmpty) {
        return null;
      }

      // Step 3: Sort by scheduled time and get nearest
      upcomingReminders.sort((a, b) {
        Timestamp timeA = a['scheduledTime'];
        Timestamp timeB = b['scheduledTime'];
        return timeA.compareTo(timeB);
      });

      Map<String, dynamic> nearestReminder = upcomingReminders.first;

      // Step 4: Fetch assigned user details
      String? assignedTo = nearestReminder['assignedTo'];
      if (assignedTo != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(assignedTo)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          nearestReminder['assignedUserName'] = userData['name'] ?? 'Unknown';
          nearestReminder['assignedUserEmail'] = userData['email'] ?? '';
        }
      }

      // Step 5: Fetch group name
      String groupId = nearestReminder['groupId'];
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();
      if (groupDoc.exists) {
        Map<String, dynamic> groupData =
            groupDoc.data() as Map<String, dynamic>;
        nearestReminder['groupName'] =
            groupData['groupName'] ?? 'Unknown Group';
      }

      return nearestReminder;
    } catch (e) {
      throw Exception('Failed to get nearest upcoming reminder: $e');
    }
  }

  /// Get nearest upcoming reminder stream (real-time)
  Stream<Map<String, dynamic>?> getNearestUpcomingReminderStream(
    String caregiverId,
  ) async* {
    try {
      // Get groups caregiver manages
      QuerySnapshot adminGroupsSnapshot = await _firestore
          .collection('groups')
          .where('adminId', isEqualTo: caregiverId)
          .get();

      List<String> groupIds = adminGroupsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      if (groupIds.isEmpty) {
        yield null;
        return;
      }

      // Stream reminders from all groups
      DateTime now = DateTime.now();
      Timestamp nowTimestamp = Timestamp.fromDate(now);

      // For simplicity, we'll poll every few seconds
      // In production, you might want a more sophisticated approach
      await for (var _ in Stream.periodic(const Duration(seconds: 30))) {
        Map<String, dynamic>? nearest = await getNearestUpcomingReminder(
          caregiverId,
        );
        yield nearest;
      }
    } catch (e) {
      yield null;
    }
  }

  /// Format repeat type display name
  String getRepeatTypeDisplayName(
    String repeatType, [
    List<dynamic>? repeatDays,
  ]) {
    if (repeatType == 'specific_days' && repeatDays != null) {
      if (repeatDays.length == 7) return 'Every day';
      if (repeatDays.length == 2 &&
          repeatDays.contains(6) &&
          repeatDays.contains(7)) {
        return 'Weekends';
      }

      List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      // Sort and map to names
      List<int> sortedDays = List<int>.from(repeatDays)..sort();
      return sortedDays.map((d) => days[d - 1]).join(', ');
    }

    switch (repeatType.toLowerCase()) {
      case 'once':
        return 'One-time';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Custom';
    }
  }

  /// Format time remaining until reminder
  String getTimeUntilReminder(Timestamp scheduledTime) {
    DateTime scheduled = scheduledTime.toDate();
    DateTime now = DateTime.now();
    Duration difference = scheduled.difference(now);

    if (difference.isNegative) {
      return 'Now';
    }

    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    } else {
      // Format as date
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
      return '${scheduled.day} ${months[scheduled.month - 1]}';
    }
  }

  /// Get upcoming reminders for a group (caregiver view - all reminders)
  /// This fetches ALL upcoming reminders, not just the next 5
  Future<List<Map<String, dynamic>>> getAllUpcomingRemindersForGroup(
    String groupId,
  ) async {
    try {
      DateTime now = DateTime.now();
      Timestamp nowTimestamp = Timestamp.fromDate(now);

      QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('groupId', isEqualTo: groupId)
          .where('scheduledTime', isGreaterThanOrEqualTo: nowTimestamp)
          .orderBy('scheduledTime', descending: false)
          .get();

      List<Map<String, dynamic>> reminders = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['reminderId'] = doc.id;

        // Only include if not completed (or if recurring)
        bool isCompleted = data['isCompleted'] ?? false;
        String repeatType = data['repeatType'] ?? 'once';

        if (!isCompleted || repeatType != 'once') {
          reminders.add(data);
        }
      }

      return reminders;
    } catch (e) {
      throw Exception('Failed to fetch upcoming reminders: $e');
    }
  }

  /// Get elderly user display name
  Future<String> getElderlyDisplayName(String elderlyId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(elderlyId)
          .get();

      if (!userDoc.exists) {
        return 'Unknown User';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String name = userData['name'] ?? '';

      if (name.isNotEmpty) {
        return name;
      }

      // Fallback to email
      String email = userData['email'] ?? '';
      if (email.isNotEmpty) {
        return email.split('@').first;
      }

      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  /// MARKS A TASK AS COMPLETE (History Log Pattern)
  /// 1. Creates a record in 'reminder_history' (preserving the old due date).
  /// 2. Updates the active 'reminder' to the NEXT occurrence using robust calculation.
  Future<void> completeRecurringTask({
    required String reminderId,
    required String title,
    required DateTime currentDueDate,
    required String repeatInterval, // mapped from 'repeatType'
    List<int>? repeatDays,
    String? forceStatus,
  }) async {
    WriteBatch batch = _firestore.batch();

    DocumentReference reminderRef = _firestore
        .collection('reminders')
        .doc(reminderId);
    DocumentReference historyRef = _firestore
        .collection('reminder_history')
        .doc();

    final now = DateTime.now();
    String status = 'completed';

    // 1. Determine Status
    if (forceStatus != null) {
      status = forceStatus;
    } else if (now.isAfter(currentDueDate.add(const Duration(hours: 1)))) {
      status = 'overdue';
    }

    // 2. Add to History (We always want a history log, even for one-time tasks)
    batch.set(historyRef, {
      'originalReminderId': reminderId,
      'taskTitle': title,
      'completedAt': FieldValue.serverTimestamp(),
      'scheduledFor': currentDueDate,
      'status': status,
      'notes': status == 'missed'
          ? 'Auto-archived by system'
          : (status == 'overdue' ? 'Completed late' : 'On time'),
    });

    // 3. Update Active Reminder based on Repeat Type
    if (repeatInterval == 'once') {
      // CASE A: One-time Task -> Just mark as COMPLETED
      batch.update(reminderRef, {
        'isCompleted': true, // This hides it from the active list
        'lastCompleted': FieldValue.serverTimestamp(),
        // We do NOT change scheduledTime for one-time tasks
      });
    } else {
      // CASE B: Recurring Task -> RESCHEDULE for next time
      DateTime nextDueDate = _calculateNextOccurrence(
        currentDueDate,
        repeatInterval,
        repeatDays,
      );

      batch.update(reminderRef, {
        'scheduledTime': Timestamp.fromDate(nextDueDate),
        'lastCompleted': FieldValue.serverTimestamp(),
        'isCompleted': false, // Keep false so it stays active for next cycle
        'isOverdueNotified': false,
      });
    }

    try {
      // 1. Get current user (Elderly)
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 2. Get the reminder to find the Group ID
      DocumentSnapshot reminderDoc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();
      String groupId = '';
      if (reminderDoc.exists) {
        groupId = (reminderDoc.data() as Map<String, dynamic>)['groupId'] ?? '';
      }

      // 3. Notify if we have a Group ID
      if (groupId.isNotEmpty) {
        Map<String, dynamic>? user = await getUserDetails(currentUserId);
        await _notificationService.notifyCaregiversOfCompletion(
          groupId,
          user?['name'] ?? 'Elderly',
          title,
        );
      }
    } catch (e) {
      print("Error sending completion notification: $e");
    }
    await batch.commit();
  }

  /// AUTOMATICALLY HANDLES MISSED REMINDERS
  /// 1. Logs them as 'missed' in history.
  /// 2. Reschedules recurring tasks to the future.
  /// 3. Closes one-time tasks.
  Future<void> processMissedReminders(
    List<Map<String, dynamic>> reminders,
  ) async {
    final batch = _firestore.batch();
    bool hasUpdates = false;
    final now = DateTime.now();

    for (var reminder in reminders) {
      if (reminder['isCompleted'] == true) continue;

      Timestamp scheduledTs = reminder['scheduledTime'];
      DateTime scheduledDateTime = scheduledTs.toDate();

      // Only process if it is SIGNIFICANTLY late (e.g., 24 hours)
      // or if it is a recurring task that needs rescheduling.
      if (scheduledDateTime.isBefore(now)) {
        String reminderId = reminder['reminderId'];
        String repeatType = reminder['repeatType'] ?? 'once';

        // --- FIXED LOGIC START ---

        if (repeatType == 'once') {
          // DO NOTHING.
          // Leave 'isCompleted' as false so the UI shows it as RED/OVERDUE.
          continue;
        }

        // --- FIXED LOGIC END ---

        // Only reschedule Recurring tasks
        hasUpdates = true;

        // ... (Keep your recurring logic below intact) ...
        List<int>? repeatDays;
        if (reminder['repeatDays'] != null) {
          repeatDays = List<int>.from(reminder['repeatDays']);
        }

        DateTime nextTime = scheduledDateTime;
        while (nextTime.isBefore(now)) {
          nextTime = _calculateNextOccurrence(nextTime, repeatType, repeatDays);
        }

        // Log the missed occurrence to history
        DocumentReference historyRef = _firestore
            .collection('reminder_history')
            .doc();
        batch.set(historyRef, {
          'originalReminderId': reminderId,
          'groupId': reminder['groupId'],
          'taskTitle': reminder['title'],
          'scheduledFor': scheduledTs,
          'status': 'missed',
          'loggedAt': FieldValue.serverTimestamp(),
        });

        // Update the main reminder to the new future time
        batch.update(_firestore.collection('reminders').doc(reminderId), {
          'scheduledTime': Timestamp.fromDate(nextTime),
          'isCompleted': false,
          'isOverdueNotified': false,
        });
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }
}
