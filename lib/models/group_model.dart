// lib/models/group_model.dart

class GroupModel {
  final String id;
  final String groupName;
  final int numberOfElderly;
  final int numberOfCaregivers;
  final int totalUpcomingReminders;

  GroupModel({
    required this.id,
    required this.groupName,
    required this.numberOfElderly,
    required this.numberOfCaregivers,
    required this.totalUpcomingReminders,
  });
}
