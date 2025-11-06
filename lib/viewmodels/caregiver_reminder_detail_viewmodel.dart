// lib/viewmodels/caregiver_reminder_detail_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class CaregiverReminderDetailViewModel extends ChangeNotifier {
  ReminderModel? _reminder;
  String? _elderlyName;
  bool _isLoading = false;
  bool _isPlayingVoiceNote = false;
  bool _isRecordingVoiceNote = false;
  String _currentReminderType = 'medicine'; // Default type

  ReminderModel? get reminder => _reminder;
  String? get elderlyName => _elderlyName;
  bool get isLoading => _isLoading;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  bool get isRecordingVoiceNote => _isRecordingVoiceNote;
  String get currentReminderType => _currentReminderType;

  CaregiverReminderDetailViewModel() {
    _loadDummyReminder(_currentReminderType);
  }

  void changeReminderType(String type) {
    _currentReminderType = type;
    _isPlayingVoiceNote = false;
    _isRecordingVoiceNote = false;
    _loadDummyReminder(type);
  }

  void _loadDummyReminder(String reminderType) {
    _isLoading = true;
    notifyListeners();

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final now = DateTime.now();

      if (reminderType == 'medicine') {
        _reminder = ReminderModel(
          id: '1',
          title: 'Take Blood Pressure Medicine',
          description:
              'Remember to take with a full glass of water. Do not skip this medication.',
          dateTime: DateTime(now.year, now.month, now.day, 8, 0),
          type: 'medicine',
          isRecurring: true,
          recurringPattern: 'Daily',
          durationMinutes: 5,
          medicineName: 'Amlodipine',
          dosage: '5mg - 1 tablet',
          frequencyPerDay: 2,
          mealTiming: 'after',
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 45,
        );
        _elderlyName = 'Mr. Lee';
      } else if (reminderType == 'appointment') {
        _reminder = ReminderModel(
          id: '2',
          title: 'Doctor Appointment',
          description:
              'Annual checkup with Dr. Smith. Please bring your medical history and current medication list.',
          dateTime: now.add(const Duration(days: 3, hours: 2)),
          type: 'appointment',
          isRecurring: false,
          durationMinutes: 60,
          venueName: 'City General Hospital - Room 302',
          hasAppointmentCardScan: true,
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 32,
        );
        _elderlyName = 'Mrs. Wong';
      } else {
        _reminder = ReminderModel(
          id: '3',
          title: 'Morning Exercise',
          description:
              'Light stretching and walking routine. Remember to warm up first.',
          dateTime: DateTime(now.year, now.month, now.day, 7, 30),
          type: 'task',
          isRecurring: true,
          recurringPattern: 'Daily',
          durationMinutes: 30,
          hasVoiceNote: false,
        );
        _elderlyName = 'Mr. Lee';
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  void toggleVoiceNotePlayback() {
    if (_reminder == null || !_reminder!.hasVoiceNote) return;

    _isPlayingVoiceNote = !_isPlayingVoiceNote;
    notifyListeners();

    // Simulate audio playback completion
    if (_isPlayingVoiceNote) {
      Future.delayed(
          Duration(seconds: _reminder!.voiceNoteDurationSeconds ?? 0), () {
        _isPlayingVoiceNote = false;
        notifyListeners();
      });
    }
  }

  // TODO: Implement actual voice recording logic
  void startRecordingVoiceNote() {
    _isRecordingVoiceNote = true;
    notifyListeners();

    // Simulate recording for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _isRecordingVoiceNote = false;
      // Simulate saving voice note
      if (_reminder != null) {
        _reminder = ReminderModel(
          id: _reminder!.id,
          title: _reminder!.title,
          description: _reminder!.description,
          dateTime: _reminder!.dateTime,
          type: _reminder!.type,
          isRecurring: _reminder!.isRecurring,
          recurringPattern: _reminder!.recurringPattern,
          durationMinutes: _reminder!.durationMinutes,
          medicineName: _reminder!.medicineName,
          dosage: _reminder!.dosage,
          frequencyPerDay: _reminder!.frequencyPerDay,
          mealTiming: _reminder!.mealTiming,
          venueName: _reminder!.venueName,
          hasAppointmentCardScan: _reminder!.hasAppointmentCardScan,
          hasVoiceNote: true,
          voiceNoteDurationSeconds: 3,
        );
      }
      notifyListeners();
    });
  }

  void deleteReminder() {
    // TODO: Implement actual deletion logic with backend API
    _reminder = null;
    notifyListeners();
  }

  void refreshReminder() {
    _loadDummyReminder(_currentReminderType);
  }
}
