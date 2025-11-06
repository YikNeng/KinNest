import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../models/user_model.dart';

class CaregiverHomeViewModel extends ChangeNotifier {
  List<ReminderModel> _upcomingReminders = [];
  int _numberOfGroups = 0;
  int _numberOfElderly = 0;
  int _numberOfRemindersToday = 0;

  List<ReminderModel> get upcomingReminders => _upcomingReminders;
  int get numberOfGroups => _numberOfGroups;
  int get numberOfElderly => _numberOfElderly;
  int get numberOfRemindersToday => _numberOfRemindersToday;

  CaregiverHomeViewModel() {
    _loadDummyData();
  }

  void _loadDummyData() {
    // TODO: Replace with actual API call to fetch upcoming reminders across all groups
    _upcomingReminders = [
      ReminderModel(
        id: '1',
        title: 'Take Blood Pressure Medicine',
        description: 'Take medication with water',
        dateTime: DateTime.now().add(Duration(hours: 1)),
        isCompleted: false,
        elderlyName: 'John Tan',
        elderlyId: 'elderly_1',
      ),
      ReminderModel(
        id: '2',
        title: 'Lunch Time',
        description: 'Have balanced meal',
        dateTime: DateTime.now().add(Duration(hours: 2)),
        isCompleted: false,
        elderlyName: 'Mary Lim',
        elderlyId: 'elderly_2',
      ),
      ReminderModel(
        id: '3',
        title: 'Afternoon Walk',
        description: 'Light exercise in park',
        dateTime: DateTime.now().add(Duration(hours: 3)),
        isCompleted: false,
        elderlyName: 'Robert Wong',
        elderlyId: 'elderly_3',
      ),
      ReminderModel(
        id: '4',
        title: 'Evening Medicine',
        description: 'Diabetes medication',
        dateTime: DateTime.now().add(Duration(hours: 5)),
        isCompleted: false,
        elderlyName: 'John Tan',
        elderlyId: 'elderly_1',
      ),
    ];

    // TODO: Replace with actual API call to fetch caregiver statistics
    _numberOfGroups = 2;
    _numberOfElderly = 5;
    _numberOfRemindersToday = 4;

    notifyListeners();
  }

  void refreshData() {
    // TODO: Implement refresh logic to fetch updated data from backend
    _loadDummyData();
  }
}
