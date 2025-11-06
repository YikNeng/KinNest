// lib/viewmodels/caregiver_group_detail_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';

class CaregiverGroupDetailViewModel extends ChangeNotifier {
  GroupModel? _group;
  List<UserModel> _elderlyMembers = [];
  List<UserModel> _caregiverMembers = [];
  List<Map<String, dynamic>> _upcomingReminders = [];
  bool _isLoading = false;

  GroupModel? get group => _group;
  List<UserModel> get elderlyMembers => _elderlyMembers;
  List<UserModel> get caregiverMembers => _caregiverMembers;
  List<Map<String, dynamic>> get upcomingReminders => _upcomingReminders;
  bool get isLoading => _isLoading;

  CaregiverGroupDetailViewModel() {
    _loadDummyGroupData();
  }

  void _loadDummyGroupData() {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with actual API call to fetch group details
    Future.delayed(const Duration(milliseconds: 300), () {
      _group = GroupModel(
        id: '1',
        groupName: 'Family Care Group',
        numberOfElderly: 3,
        numberOfCaregivers: 2,
        totalUpcomingReminders: 5,
      );

      _elderlyMembers = [
        UserModel(
          id: 'elderly_1',
          username: 'Mrs. Lim',
          email: 'mrlee@email.com',
          hashedPassword: 'hashed',
          age: 72,
          heightCm: 168.0,
          weightKg: 65.0,
          chronicDisease: true,
          chronicDiseaseNotes: 'Hypertension',
          role: UserRole.elderly,
        ),
        UserModel(
          id: 'elderly_2',
          username: 'Mrs. Chan',
          email: 'mrschan@email.com',
          hashedPassword: 'hashed',
          age: 68,
          heightCm: 155.0,
          weightKg: 58.0,
          chronicDisease: true,
          chronicDiseaseNotes: 'Diabetes',
          role: UserRole.elderly,
        ),
        UserModel(
          id: 'elderly_3',
          username: 'Uncle Tan',
          email: 'uncletan@email.com',
          hashedPassword: 'hashed',
          age: 75,
          heightCm: 170.0,
          weightKg: 70.0,
          chronicDisease: false,
          chronicDiseaseNotes: '',
          role: UserRole.elderly,
        ),
      ];

      _caregiverMembers = [
        UserModel(
          id: 'caregiver_1',
          username: 'Sarah Wong',
          email: 'sarah@email.com',
          hashedPassword: 'hashed',
          age: 35,
          heightCm: 165.0,
          weightKg: 60.0,
          chronicDisease: false,
          chronicDiseaseNotes: '',
          role: UserRole.caregiver,
        ),
        UserModel(
          id: 'caregiver_2',
          username: 'David Lim',
          email: 'david@email.com',
          hashedPassword: 'hashed',
          age: 42,
          heightCm: 175.0,
          weightKg: 75.0,
          chronicDisease: false,
          chronicDiseaseNotes: '',
          role: UserRole.caregiver,
        ),
      ];

      final now = DateTime.now();
      _upcomingReminders = [
        {
          'reminder': ReminderModel(
            id: '1',
            title: 'Morning Blood Pressure Medicine',
            description: 'Take medication with water',
            dateTime: DateTime(now.year, now.month, now.day, 8, 0),
            type: 'medicine',
            isRecurring: true,
            recurringPattern: 'Daily',
            medicineName: 'Amlodipine',
            dosage: '5mg',
            hasVoiceNote: true,
            voiceNoteDurationSeconds: 45,
          ),
          'elderlyName': 'Mrs. Lim',
          'elderlyId': 'elderly_1',
        },
        {
          'reminder': ReminderModel(
            id: '2',
            title: 'Diabetes Checkup',
            description: 'Monthly checkup at clinic',
            dateTime: now.add(const Duration(days: 2)),
            type: 'appointment',
            isRecurring: true,
            recurringPattern: 'Monthly',
            venueName: 'City Medical Centre',
            hasVoiceNote: false,
          ),
          'elderlyName': 'Mrs. Chan',
          'elderlyId': 'elderly_2',
        },
        {
          'reminder': ReminderModel(
            id: '3',
            title: 'Afternoon Walk',
            description: 'Light exercise routine',
            dateTime: DateTime(now.year, now.month, now.day, 15, 0),
            type: 'task',
            isRecurring: true,
            recurringPattern: 'Daily',
            durationMinutes: 20,
            hasVoiceNote: true,
            voiceNoteDurationSeconds: 28,
          ),
          'elderlyName': 'Uncle Tan',
          'elderlyId': 'elderly_3',
        },
        {
          'reminder': ReminderModel(
            id: '4',
            title: 'Evening Insulin',
            description: 'Take insulin injection',
            dateTime: DateTime(now.year, now.month, now.day, 19, 0),
            type: 'medicine',
            isRecurring: true,
            recurringPattern: 'Daily',
            medicineName: 'Insulin',
            dosage: '10 units',
            hasVoiceNote: false,
          ),
          'elderlyName': 'Mrs. Chan',
          'elderlyId': 'elderly_2',
        },
        {
          'reminder': ReminderModel(
            id: '5',
            title: 'Lunch Reminder',
            description: 'Healthy balanced meal',
            dateTime: DateTime(now.year, now.month, now.day, 12, 30),
            type: 'task',
            isRecurring: true,
            recurringPattern: 'Daily',
            hasVoiceNote: false,
          ),
          'elderlyName': 'Mrs. Lim',
          'elderlyId': 'elderly_1',
        },
      ];

      _isLoading = false;
      notifyListeners();
    });
  }

  void refreshGroupData() {
    // TODO: Implement refresh logic to fetch updated data from backend
    _loadDummyGroupData();
  }

  void addMember() {
    // TODO: Implement add member logic
  }
}
