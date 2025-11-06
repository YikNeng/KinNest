import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ElderlyReminderCreateViewModel extends ChangeNotifier {
  // Form controllers
  final TextEditingController titleController =
      TextEditingController(text: 'Take morning meds');
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController durationController =
      TextEditingController(text: '5');
  final TextEditingController medicineNameController =
      TextEditingController(text: 'Aspirin');
  final TextEditingController dosageController =
      TextEditingController(text: '1 tablet');
  final TextEditingController venueController = TextEditingController();

  ReminderType _selectedType = ReminderType.medication;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  String _recurringPattern = 'Daily';
  int _frequencyPerDay = 2;
  String _mealTiming = 'after';
  bool _hasAppointmentCardScan = false;

  // Validation errors
  String? _titleError;
  String? _dateTimeError;

  ReminderType get selectedType => _selectedType;
  DateTime get selectedDateTime => _selectedDateTime;
  bool get isRecurring => _isRecurring;
  String get recurringPattern => _recurringPattern;
  int get frequencyPerDay => _frequencyPerDay;
  String get mealTiming => _mealTiming;
  bool get hasAppointmentCardScan => _hasAppointmentCardScan;
  String? get titleError => _titleError;
  String? get dateTimeError => _dateTimeError;

  void setReminderType(ReminderType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setDateTime(DateTime dateTime) {
    _selectedDateTime = dateTime;
    _dateTimeError = null;
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

  void setAppointmentCardScan(bool value) {
    _hasAppointmentCardScan = value;
    notifyListeners();
  }

  // TODO: Future integration point - connect to camera/scanner for appointment card
  void scanAppointmentCard() {
    // Placeholder for scanning functionality
    // Will integrate with camera and OCR in future
    _hasAppointmentCardScan = true;
    notifyListeners();
  }

  bool validateFields() {
    bool isValid = true;

    // Validate title
    if (titleController.text.trim().isEmpty) {
      _titleError = 'Title is required';
      isValid = false;
    } else {
      _titleError = null;
    }

    // Validate date/time
    if (_selectedDateTime.isBefore(DateTime.now())) {
      _dateTimeError = 'Date & time must be in the future';
      isValid = false;
    } else {
      _dateTimeError = null;
    }

    // Type-specific validation
    if (_selectedType == ReminderType.medication &&
        medicineNameController.text.trim().isEmpty) {
      isValid = false;
    }

    if (_selectedType == ReminderType.appointment &&
        venueController.text.trim().isEmpty) {
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  // TODO: Future integration point - save to backend API
  Future<bool> saveReminder() async {
    if (!validateFields()) {
      return false;
    }

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // Example:
    // final response = await apiService.createReminder(
    //   title: titleController.text,
    //   type: _selectedType.value,
    //   dateTime: _selectedDateTime,
    //   ...
    // );

    // For now, just return success
    return true;
  }

  ReminderModel buildReminderModel() {
    return ReminderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text,
      description: descriptionController.text,
      dateTime: _selectedDateTime,
      type: _selectedType.value,
      isRecurring: _isRecurring,
      recurringPattern: _isRecurring ? _recurringPattern : null,
      durationMinutes: durationController.text.isNotEmpty
          ? int.tryParse(durationController.text)
          : null,
      medicineName: _selectedType == ReminderType.medication
          ? medicineNameController.text
          : null,
      dosage: _selectedType == ReminderType.medication
          ? dosageController.text
          : null,
      frequencyPerDay:
          _selectedType == ReminderType.medication ? _frequencyPerDay : null,
      mealTiming: _selectedType == ReminderType.medication ? _mealTiming : null,
      venueName: _selectedType == ReminderType.appointment
          ? venueController.text
          : null,
      hasAppointmentCardScan: _selectedType == ReminderType.appointment
          ? _hasAppointmentCardScan
          : null,
      hasVoiceNote: false,
    );
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
