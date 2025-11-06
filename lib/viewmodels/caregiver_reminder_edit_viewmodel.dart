// lib/viewmodels/caregiver_reminder_edit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class CaregiverReminderEditViewModel extends ChangeNotifier {
  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController venueController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  bool _isRecurring = false;
  String _recurringPattern = 'Daily';
  String _reminderType = 'medicine';
  int _frequencyPerDay = 1;
  String _mealTiming = 'after';
  bool _hasAppointmentCardScan = false;
  bool _hasVoiceNote = false;
  int? _voiceNoteDurationSeconds;
  bool _isPlayingVoiceNote = false;
  bool _isRecordingVoiceNote = false;
  bool _isLoading = false;
  String? _elderlyName;
  ReminderType _selectedReminderType = ReminderType.medication;

  DateTime get selectedDateTime => _selectedDateTime;
  bool get isRecurring => _isRecurring;
  String get recurringPattern => _recurringPattern;
  String get reminderType => _reminderType;
  int get frequencyPerDay => _frequencyPerDay;
  String get mealTiming => _mealTiming;
  bool get hasAppointmentCardScan => _hasAppointmentCardScan;
  bool get hasVoiceNote => _hasVoiceNote;
  int? get voiceNoteDurationSeconds => _voiceNoteDurationSeconds;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  bool get isRecordingVoiceNote => _isRecordingVoiceNote;
  bool get isLoading => _isLoading;
  String? get elderlyName => _elderlyName;
  ReminderType get selectedReminderType => _selectedReminderType;

  CaregiverReminderEditViewModel() {
    _loadDummyReminderData();
  }

  void _loadDummyReminderData() {
    _isLoading = true;
    notifyListeners();

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final now = DateTime.now();

      // Load dummy data (change _reminderType to test different types)
      _reminderType = 'medicine'; // Change to 'appointment' or 'task' to test
      _selectedReminderType = ReminderType.medication;

      if (_reminderType == 'medicine') {
        titleController.text = 'Morning Blood Pressure Medicine';
        descriptionController.text =
            'Take medication with a full glass of water. Do not skip this medication.';
        _selectedDateTime = DateTime(now.year, now.month, now.day, 8, 0);
        durationController.text = '5';
        _isRecurring = true;
        _recurringPattern = 'Daily';
        medicineNameController.text = 'Amlodipine';
        dosageController.text = '5mg - 1 tablet';
        _frequencyPerDay = 2;
        _mealTiming = 'after';
        _hasVoiceNote = true;
        _voiceNoteDurationSeconds = 45;
        _elderlyName = 'Mrs. Lim';
      } else if (_reminderType == 'appointment') {
        titleController.text = 'Doctor Appointment';
        descriptionController.text =
            'Annual checkup with Dr. Smith. Please bring your medical history and current medication list.';
        _selectedDateTime = now.add(const Duration(days: 3, hours: 2));
        durationController.text = '60';
        _isRecurring = false;
        venueController.text = 'City General Hospital - Room 302';
        _hasAppointmentCardScan = true;
        _hasVoiceNote = true;
        _voiceNoteDurationSeconds = 32;
        _elderlyName = 'Mrs. Wong';
        _selectedReminderType = ReminderType.appointment;
      } else {
        titleController.text = 'Morning Exercise';
        descriptionController.text =
            'Light stretching and walking routine. Remember to warm up first.';
        _selectedDateTime = DateTime(now.year, now.month, now.day, 7, 30);
        durationController.text = '30';
        _isRecurring = true;
        _recurringPattern = 'Daily';
        _hasVoiceNote = false;
        _elderlyName = 'Mrs. Lim';
        _selectedReminderType = ReminderType.task;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  void setReminderType(ReminderType type) {
    _selectedReminderType = type;
    _reminderType = type.value;
    notifyListeners();
  }

  void setDateTime(DateTime dateTime) {
    _selectedDateTime = dateTime;
    notifyListeners();
  }

  void setIsRecurring(bool value) {
    _isRecurring = value;
    notifyListeners();
  }

  void setRecurringPattern(String pattern) {
    _recurringPattern = pattern;
    notifyListeners();
  }

  void setFrequencyPerDay(int frequency) {
    _frequencyPerDay = frequency;
    notifyListeners();
  }

  void setMealTiming(String timing) {
    _mealTiming = timing;
    notifyListeners();
  }

  void scanAppointmentCard() {
    _hasAppointmentCardScan = true;
    notifyListeners();
  }

  // TODO: Future integration point - connect to audio recording service
  void startRecordingVoiceNote() {
    _isRecordingVoiceNote = true;
    notifyListeners();

    // Simulate recording for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _isRecordingVoiceNote = false;
      _hasVoiceNote = true;
      _voiceNoteDurationSeconds = 3;
      notifyListeners();
    });
  }

  void toggleVoiceNotePlayback() {
    if (!_hasVoiceNote) return;

    _isPlayingVoiceNote = !_isPlayingVoiceNote;
    notifyListeners();

    if (_isPlayingVoiceNote) {
      Future.delayed(Duration(seconds: _voiceNoteDurationSeconds ?? 0), () {
        _isPlayingVoiceNote = false;
        notifyListeners();
      });
    }
  }

  void removeVoiceNote() {
    _hasVoiceNote = false;
    _voiceNoteDurationSeconds = null;
    notifyListeners();
  }

  String getVoiceNoteDuration() {
    if (_voiceNoteDurationSeconds == null) return '0:00';
    final minutes = _voiceNoteDurationSeconds! ~/ 60;
    final seconds = _voiceNoteDurationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String? validateFields() {
    if (titleController.text.trim().isEmpty) {
      return 'Please enter a title';
    }
    if (_reminderType == 'medicine' &&
        medicineNameController.text.trim().isEmpty) {
      return 'Please enter medicine name';
    }
    if (_reminderType == 'appointment' && venueController.text.trim().isEmpty) {
      return 'Please enter venue/clinic name';
    }
    return null;
  }

  Future<bool> saveChanges() async {
    final validationError = validateFields();
    if (validationError != null) {
      return false;
    }

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: In real app, save to backend here
    return true;
  }

  void deleteReminder() {
    // TODO: Implement actual deletion logic with backend API
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    medicineNameController.dispose();
    dosageController.dispose();
    venueController.dispose();
    super.dispose();
  }
}
