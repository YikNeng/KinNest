import 'package:flutter/material.dart';

class ElderlyReminderEditViewModel extends ChangeNotifier {
  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController venueController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  int _durationMinutes = 30;
  bool _isRecurring = false;
  String _recurringPattern = 'Daily';
  String _reminderType = 'medicine';
  int _frequencyPerDay = 1;
  String _mealTiming = 'after';
  bool _hasAppointmentCardScan = false;
  bool _hasVoiceNote = false;
  int? _voiceNoteDurationSeconds;
  bool _isPlayingVoiceNote = false;
  bool _isLoading = false;

  DateTime get selectedDateTime => _selectedDateTime;
  int get durationMinutes => _durationMinutes;
  bool get isRecurring => _isRecurring;
  String get recurringPattern => _recurringPattern;
  String get reminderType => _reminderType;
  int get frequencyPerDay => _frequencyPerDay;
  String get mealTiming => _mealTiming;
  bool get hasAppointmentCardScan => _hasAppointmentCardScan;
  bool get hasVoiceNote => _hasVoiceNote;
  int? get voiceNoteDurationSeconds => _voiceNoteDurationSeconds;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  bool get isLoading => _isLoading;

  ElderlyReminderEditViewModel() {
    _loadDummyReminderData();
  }

  void _loadDummyReminderData() {
    _isLoading = true;
    notifyListeners();

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final now = DateTime.now();

      // Load dummy data based on type (change _reminderType to test different types)
      _reminderType =
          'medicine'; // Change to 'appointment' or 'exercise' to test

      if (_reminderType == 'medicine') {
        titleController.text = 'Take Blood Pressure Medicine';
        descriptionController.text =
            'Remember to take with a full glass of water. Do not skip this medication.';
        _selectedDateTime = DateTime(now.year, now.month, now.day, 8, 0);
        _durationMinutes = 5;
        _isRecurring = true;
        _recurringPattern = 'Daily';
        medicineNameController.text = 'Amlodipine';
        dosageController.text = '5mg - 1 tablet';
        _frequencyPerDay = 2;
        _mealTiming = 'after';
        _hasVoiceNote = true;
        _voiceNoteDurationSeconds = 45;
      } else if (_reminderType == 'appointment') {
        titleController.text = 'Doctor Appointment';
        descriptionController.text =
            'Annual checkup with Dr. Smith. Please bring your medical history and current medication list.';
        _selectedDateTime = now.add(const Duration(days: 3, hours: 2));
        _durationMinutes = 60;
        _isRecurring = false;
        venueController.text = 'City General Hospital - Room 302';
        _hasAppointmentCardScan = true;
        _hasVoiceNote = true;
        _voiceNoteDurationSeconds = 32;
      } else {
        titleController.text = 'Morning Exercise';
        descriptionController.text =
            'Light stretching and walking routine. Remember to warm up first.';
        _selectedDateTime = DateTime(now.year, now.month, now.day, 7, 30);
        _durationMinutes = 30;
        _isRecurring = true;
        _recurringPattern = 'Daily';
        _hasVoiceNote = false;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  void setDateTime(DateTime dateTime) {
    _selectedDateTime = dateTime;
    notifyListeners();
  }

  void setDuration(int minutes) {
    _durationMinutes = minutes;
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

    // In real app, save to backend here
    return true;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    medicineNameController.dispose();
    dosageController.dispose();
    venueController.dispose();
    super.dispose();
  }
}
