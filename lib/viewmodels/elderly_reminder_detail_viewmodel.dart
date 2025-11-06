import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ElderlyReminderDetailViewModel extends ChangeNotifier {
  ReminderModel? _reminder;
  bool _isLoading = false;
  bool _isPlayingVoiceNote = false;
  String _currentReminderType = 'medicine'; // Default type

  ReminderModel? get reminder => _reminder;
  bool get isLoading => _isLoading;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  String get currentReminderType => _currentReminderType;

  ElderlyReminderDetailViewModel() {
    _loadDummyReminder(_currentReminderType);
  }

  void changeReminderType(String type) {
    _currentReminderType = type;
    _isPlayingVoiceNote = false; // Stop any playing voice note
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
      } else {
        _reminder = ReminderModel(
          id: '3',
          title: 'Morning Exercise',
          description:
              'Light stretching and walking routine. Remember to warm up first.',
          dateTime: DateTime(now.year, now.month, now.day, 7, 30),
          type: 'exercise',
          isRecurring: true,
          recurringPattern: 'Daily',
          durationMinutes: 30,
          hasVoiceNote: false,
        );
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

  void deleteReminder() {
    // In real app, this would delete from backend
    // For now, just simulate
    _reminder = null;
    notifyListeners();
  }

  void refreshReminder() {
    _loadDummyReminder(_currentReminderType);
  }
}
