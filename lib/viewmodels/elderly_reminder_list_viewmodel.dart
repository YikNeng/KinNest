import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ElderlyReminderListViewModel extends ChangeNotifier {
  List<ReminderModel> _allReminders = [];
  bool _isLoading = false;

  List<ReminderModel> get allReminders => _allReminders;
  bool get isLoading => _isLoading;

  ElderlyReminderListViewModel() {
    _loadDummyReminders();
  }

  void _loadDummyReminders() {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();

    _allReminders = [
      ReminderModel(
        id: '1',
        title: 'Take Blood Pressure Medicine',
        description: 'Take 1 tablet of Amlodipine 5mg',
        dateTime: DateTime(now.year, now.month, now.day, 8, 0),
        type: 'medicine',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '2',
        title: 'Doctor Appointment',
        description: 'Dr. Smith - General Checkup at City Hospital',
        dateTime: now.add(const Duration(days: 3, hours: 2)),
        type: 'appointment',
        isRecurring: false,
      ),
      ReminderModel(
        id: '3',
        title: 'Morning Exercise',
        description: 'Light stretching and walking routine',
        dateTime: DateTime(now.year, now.month, now.day, 7, 30),
        type: 'exercise',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '4',
        title: 'Take Vitamins',
        description: 'Multivitamin and Calcium supplements',
        dateTime: DateTime(now.year, now.month, now.day, 9, 0),
        type: 'medicine',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '5',
        title: 'Physiotherapy Session',
        description: 'Weekly session at Wellness Center',
        dateTime: now.add(const Duration(days: 2)),
        type: 'appointment',
        isRecurring: true,
        recurringPattern: 'Weekly',
      ),
      ReminderModel(
        id: '6',
        title: 'Take Diabetes Medicine',
        description: 'Metformin 500mg after lunch',
        dateTime: DateTime(now.year, now.month, now.day, 13, 0),
        type: 'medicine',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '7',
        title: 'Yoga Class',
        description: 'Senior yoga class at community center',
        dateTime: now.add(const Duration(days: 1, hours: -8)),
        type: 'exercise',
        isRecurring: true,
        recurringPattern: 'Weekly',
      ),
      ReminderModel(
        id: '8',
        title: 'Eye Check-up',
        description: 'Annual eye examination with Dr. Lee',
        dateTime: now.add(const Duration(days: 14)),
        type: 'appointment',
        isRecurring: false,
      ),
      ReminderModel(
        id: '9',
        title: 'Yesterday Morning Walk',
        description: 'Completed morning walk',
        dateTime: now.subtract(const Duration(days: 1, hours: 14)),
        type: 'exercise',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '10',
        title: 'Yesterday Medicine',
        description: 'Took evening medicine',
        dateTime: now.subtract(const Duration(days: 1, hours: 5)),
        type: 'medicine',
        isRecurring: true,
        recurringPattern: 'Daily',
      ),
      ReminderModel(
        id: '11',
        title: 'Last Week Checkup',
        description: 'Completed dental checkup',
        dateTime: now.subtract(const Duration(days: 5)),
        type: 'appointment',
        isRecurring: false,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void refreshReminders() {
    _loadDummyReminders();
  }

  List<ReminderModel> getUpcomingReminders() {
    final now = DateTime.now();
    return _allReminders.where((r) => r.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<ReminderModel> getPastReminders() {
    final now = DateTime.now();
    return _allReminders
        .where(
            (r) => r.dateTime.isBefore(now) || r.dateTime.isAtSameMomentAs(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
}
