import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ElderlyHomeViewModel extends ChangeNotifier {
  List<ReminderModel> _upcomingReminders = [];

  List<ReminderModel> get upcomingReminders => _upcomingReminders;

  ElderlyHomeViewModel() {
    _loadDummyReminders();
  }

  void _loadDummyReminders() {
    final now = DateTime.now();

    _upcomingReminders = [
      ReminderModel(
        id: '1',
        title: 'Take Medicine',
        description: 'Blood pressure medication',
        dateTime: now.add(const Duration(hours: 2)),
        type: 'medicine',
      ),
      ReminderModel(
        id: '2',
        title: 'Doctor Appointment',
        description: 'Dr. Smith - General Checkup',
        dateTime: now.add(const Duration(days: 1, hours: 3)),
        type: 'appointment',
      ),
      ReminderModel(
        id: '3',
        title: 'Morning Exercise',
        description: 'Light stretching routine',
        dateTime: now.add(const Duration(hours: 16)),
        type: 'exercise',
      ),
      ReminderModel(
        id: '4',
        title: 'Take Vitamins',
        description: 'Daily vitamin supplements',
        dateTime: now.add(const Duration(hours: 5)),
        type: 'medicine',
      ),
    ];

    notifyListeners();
  }

  void refreshReminders() {
    _loadDummyReminders();
  }
}
