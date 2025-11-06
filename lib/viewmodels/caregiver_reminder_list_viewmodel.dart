// lib/viewmodels/caregiver_reminder_list_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class CaregiverReminderListViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _allReminders = [];
  String _selectedFilter = 'All';
  bool _isLoading = false;

  List<Map<String, dynamic>> get allReminders => _allReminders;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  CaregiverReminderListViewModel() {
    _loadDummyReminders();
  }

  void _loadDummyReminders() {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with actual API call to fetch reminders for all elderly in caregiver's groups
    final now = DateTime.now();

    _allReminders = [
      {
        'reminder': ReminderModel(
          id: '1',
          title: 'Morning Blood Pressure Medicine',
          description: 'Take Amlodipine 5mg with water',
          dateTime: DateTime(now.year, now.month, now.day, 8, 0),
          type: 'medicine',
          isRecurring: true,
          recurringPattern: 'Daily',
          medicineName: 'Amlodipine',
          dosage: '5mg',
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 45,
        ),
        'elderlyName': 'Mr. Lee',
        'elderlyId': 'elderly_1',
      },
      {
        'reminder': ReminderModel(
          id: '2',
          title: 'Diabetes Checkup Appointment',
          description: 'Visit Dr. Tan at City Medical Centre',
          dateTime: now.add(const Duration(days: 2, hours: 3)),
          type: 'appointment',
          isRecurring: false,
          venueName: 'City Medical Centre - Level 3',
          hasVoiceNote: false,
        ),
        'elderlyName': 'Mrs. Wong',
        'elderlyId': 'elderly_2',
      },
      {
        'reminder': ReminderModel(
          id: '3',
          title: 'Afternoon Walk',
          description: 'Light exercise - 15 minutes walk',
          dateTime: DateTime(now.year, now.month, now.day, 15, 30),
          type: 'task',
          isRecurring: true,
          recurringPattern: 'Daily',
          durationMinutes: 15,
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 32,
        ),
        'elderlyName': 'Mr. Lee',
        'elderlyId': 'elderly_1',
      },
      {
        'reminder': ReminderModel(
          id: '4',
          title: 'Evening Insulin Shot',
          description: 'Take insulin after dinner',
          dateTime: DateTime(now.year, now.month, now.day, 19, 0),
          type: 'medicine',
          isRecurring: true,
          recurringPattern: 'Daily',
          medicineName: 'Insulin',
          dosage: '10 units',
          hasVoiceNote: false,
        ),
        'elderlyName': 'Mrs. Tan',
        'elderlyId': 'elderly_3',
      },
      {
        'reminder': ReminderModel(
          id: '5',
          title: 'Physiotherapy Session',
          description: 'Weekly therapy at Wellness Center',
          dateTime: now.add(const Duration(days: 3)),
          type: 'appointment',
          isRecurring: true,
          recurringPattern: 'Weekly',
          venueName: 'Wellness Center',
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 28,
        ),
        'elderlyName': 'Mrs. Wong',
        'elderlyId': 'elderly_2',
      },
      {
        'reminder': ReminderModel(
          id: '6',
          title: 'Lunch Reminder',
          description: 'Have a balanced meal',
          dateTime: DateTime(now.year, now.month, now.day, 12, 30),
          type: 'task',
          isRecurring: true,
          recurringPattern: 'Daily',
          hasVoiceNote: false,
        ),
        'elderlyName': 'Mr. Lee',
        'elderlyId': 'elderly_1',
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
    // TODO: Implement actual filtering logic based on selected filter
    // - 'All': show all reminders
    // - 'Today': filter reminders where dateTime is today
    // - 'Upcoming': filter reminders where dateTime is in the future
    // - 'Recurring': filter reminders where isRecurring = true
  }

  List<Map<String, dynamic>> getFilteredReminders() {
    // TODO: Replace with actual filter logic from backend or local filtering
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    switch (_selectedFilter) {
      case 'Today':
        return _allReminders.where((item) {
          final reminder = item['reminder'] as ReminderModel;
          final reminderDate = DateTime(
            reminder.dateTime.year,
            reminder.dateTime.month,
            reminder.dateTime.day,
          );
          return reminderDate.isAtSameMomentAs(today);
        }).toList();
      case 'Upcoming':
        return _allReminders.where((item) {
          final reminder = item['reminder'] as ReminderModel;
          return reminder.dateTime.isAfter(now);
        }).toList();
      case 'Recurring':
        return _allReminders.where((item) {
          final reminder = item['reminder'] as ReminderModel;
          return reminder.isRecurring;
        }).toList();
      default:
        return _allReminders;
    }
  }

  void refreshReminders() {
    // TODO: Implement refresh logic to fetch updated data from backend
    _loadDummyReminders();
  }
}
