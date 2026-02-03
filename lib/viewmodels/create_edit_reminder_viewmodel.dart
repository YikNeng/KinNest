import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';
import '../services/voice_note_service.dart';
import '../services/ocr_service.dart';
import '../services/group_service.dart';
import '../services/alarm_service.dart';

class CreateEditReminderViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final OCRService _ocrService = OCRService();
  final GroupService _groupService = GroupService();
  final AlarmService _alarmService = AlarmService();

  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final String groupId;
  final String? reminderId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // State variables
  String _selectedType = 'general';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Repeat selection
  Set<int> _selectedRepeatDays = {};

  // Medication Specifics
  String _medicationFrequency = 'once';
  int _doseCount = 1;
  List<TimeOfDay> _doseTimes = [const TimeOfDay(hour: 8, minute: 0)];

  File? _voiceNoteFile;
  String? _existingVoiceNoteUrl;
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _medications = [];
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isLoading = false;
  bool _isFetchingData = false;
  bool _isProcessingOCR = false;
  String? _errorMessage;
  String? _assignedToUserId;
  bool _isPlayingVoiceNote = false;
  double _voiceNotePlaybackPosition = 0.0;
  double _voiceNoteDuration = 0.0;

  // Medication controllers for each medication row
  Map<int, Map<String, TextEditingController>> _medicationControllers = {};

  // Reminder types
  final List<String> reminderTypes = ['General', 'Medication', 'Appointment'];

  // Meal timing options
  final List<String> mealTimingOptions = [
    'Before meal',
    'After meal',
    'With meal',
    'On empty stomach',
  ];

  // Getters
  String get selectedType => _selectedType;
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;
  Set<int> get selectedRepeatDays => _selectedRepeatDays;
  File? get voiceNoteFile => _voiceNoteFile;
  String? get existingVoiceNoteUrl => _existingVoiceNoteUrl;
  List<Map<String, dynamic>> get medications => _medications;
  DateTime? get appointmentDate => _appointmentDate;
  TimeOfDay? get appointmentTime => _appointmentTime;
  bool get isLoading => _isLoading;
  bool get isFetchingData => _isFetchingData;
  bool get isProcessingOCR => _isProcessingOCR;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => reminderId != null;
  bool get isCaregiver => _groupData?['adminId'] == _currentUserId;
  String? get assignedToUserId => _assignedToUserId;
  String get medicationFrequency => _medicationFrequency;
  int get doseCount => _doseCount;
  List<TimeOfDay> get doseTimes => _doseTimes;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  double get voiceNotePlaybackPosition => _voiceNotePlaybackPosition;
  double get voiceNoteDuration => _voiceNoteDuration;

  CreateEditReminderViewModel({required this.groupId, this.reminderId}) {
    _initialize();
    _setupAudioPlayerListeners();
  }

  /// Initialize
  Future<void> _initialize() async {
    _isFetchingData = true;
    notifyListeners();

    try {
      _groupData = await _groupService.getGroupDetails(groupId);

      if (isEditMode) {
        Map<String, dynamic>? reminderData = await _reminderService
            .getReminderById(reminderId!);

        if (reminderData != null) {
          _populateFormWithReminderData(reminderData);
        } else {
          _errorMessage = 'Reminder not found';
        }
      } else {
        if (_groupData != null) {
          List<Map<String, dynamic>> members = _groupData!['members'] ?? [];
          for (var member in members) {
            if (member['role'] == 'elderly') {
              _assignedToUserId = member['uid'];
              break;
            }
          }
        }
      }

      _isFetchingData = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isFetchingData = false;
      notifyListeners();
    }
  }

  /// Populate form with existing reminder data
  void _populateFormWithReminderData(Map<String, dynamic> reminderData) {
    titleController.text = reminderData['title'] ?? '';
    descriptionController.text = reminderData['description'] ?? '';
    _selectedType = reminderData['type'] ?? 'general';
    _assignedToUserId = reminderData['assignedTo'];

    Timestamp scheduledTimestamp = reminderData['scheduledTime'];
    DateTime scheduledDateTime = scheduledTimestamp.toDate();
    _selectedDate = scheduledDateTime;
    _selectedTime = TimeOfDay(
      hour: scheduledDateTime.hour,
      minute: scheduledDateTime.minute,
    );

    _doseCount = 1;
    _doseTimes = [_selectedTime];

    // Handle repeat logic conversion to Day selection
    String repeatType = reminderData['repeatType'] ?? 'once';
    if (repeatType == 'specific_days' && reminderData['repeatDays'] != null) {
      _selectedRepeatDays = Set<int>.from(reminderData['repeatDays']);
    } else if (repeatType == 'daily') {
      _selectedRepeatDays = {1, 2, 3, 4, 5, 6, 7};
    } else if (repeatType == 'weekly') {
      _selectedRepeatDays = {scheduledDateTime.weekday};
    } else {
      _selectedRepeatDays = {};
    }

    _existingVoiceNoteUrl = reminderData['voiceNoteUrl'];

    if (_selectedType == 'medication' &&
        reminderData['typeSpecificData'] != null) {
      Map<String, dynamic> typeData = reminderData['typeSpecificData'];
      if (typeData['medicationFrequency'] != null) {
        _medicationFrequency = typeData['medicationFrequency'];
      }
      if (typeData['medications'] != null) {
        _medications = List<Map<String, dynamic>>.from(
          typeData['medications'].map((m) => Map<String, dynamic>.from(m)),
        );
        _initializeMedicationControllers();
      }
    } else if (_selectedType == 'appointment' &&
        reminderData['typeSpecificData'] != null) {
      Map<String, dynamic> typeData = reminderData['typeSpecificData'];
      if (typeData['appointmentDate'] != null) {
        _appointmentDate = (typeData['appointmentDate'] as Timestamp).toDate();
      }
      if (typeData['appointmentTime'] != null) {
        String timeStr = typeData['appointmentTime'];
        List<String> parts = timeStr.split(':');
        _appointmentTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  /// Initialize controllers for medications
  void _initializeMedicationControllers() {
    for (int i = 0; i < _medications.length; i++) {
      _medicationControllers[i] = {
        'name': TextEditingController(text: _medications[i]['name'] ?? ''),
        'dosage': TextEditingController(text: _medications[i]['dosage'] ?? ''),
      };
    }
  }

  /// Get medication controller
  TextEditingController getMedicationController(int index, String field) {
    if (!_medicationControllers.containsKey(index)) {
      _medicationControllers[index] = {
        'name': TextEditingController(),
        'dosage': TextEditingController(),
      };
    }
    return _medicationControllers[index]![field]!;
  }

  /// Set reminder type
  void setReminderType(String type) {
    _selectedType = type.toLowerCase();
    _errorMessage = null;

    if (_selectedType != 'medication') {
      _medications.clear();
      _medicationControllers.clear();
    } else {
      // If switching to medication and empty
    }
    notifyListeners();
  }

  /// Set selected date
  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Set selected time
  void setTime(TimeOfDay time) {
    _selectedTime = time;
    if (_doseTimes.isNotEmpty) {
      _doseTimes[0] = time;
    }
    notifyListeners();
  }

  void incrementDose() {
    if (_doseCount < 6) {
      // Max 6 times a day
      _doseCount++;
      _recalculateDoseTimes();
      notifyListeners();
    }
  }

  void decrementDose() {
    if (_doseCount > 1) {
      _doseCount--;
      _recalculateDoseTimes();
      notifyListeners();
    }
  }

  void setDoseTime(int index, TimeOfDay time) {
    if (index >= 0 && index < _doseTimes.length) {
      _doseTimes[index] = time;
      notifyListeners();
    }
  }

  void _recalculateDoseTimes() {
    List<TimeOfDay> newTimes = [];

    // Auto-populate reasonable times based on count
    if (_doseCount == 1) {
      newTimes = [const TimeOfDay(hour: 8, minute: 0)];
    } else if (_doseCount == 2) {
      newTimes = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ];
    } else if (_doseCount == 3) {
      newTimes = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 13, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ];
    } else {
      int startHour = 8;
      int endHour = 20;
      double interval = (endHour - startHour) / (_doseCount - 1);

      for (int i = 0; i < _doseCount; i++) {
        int hour = (startHour + (interval * i)).round();
        newTimes.add(TimeOfDay(hour: hour, minute: 0));
      }
    }
    _doseTimes = newTimes;
  }

  // --- Repeat Logic ---

  void toggleDay(int day) {
    if (_selectedRepeatDays.contains(day)) {
      _selectedRepeatDays.remove(day);
    } else {
      _selectedRepeatDays.add(day);
    }
    notifyListeners();
  }

  bool isDaySelected(int day) => _selectedRepeatDays.contains(day);

  void setOneTime() {
    _selectedRepeatDays.clear();
    notifyListeners();
  }

  void setDaily() {
    _selectedRepeatDays = {1, 2, 3, 4, 5, 6, 7};
    notifyListeners();
  }

  /// Set voice note file
  void setVoiceNoteFile(File? file) {
    _voiceNoteFile = file;
    notifyListeners();
  }

  /// Remove voice note
  void removeVoiceNote() {
    stopVoiceNote();
    _voiceNoteFile = null;
    _existingVoiceNoteUrl = null;
    _voiceNoteDuration = 0.0;
    _voiceNotePlaybackPosition = 0.0;
    notifyListeners();
  }

  /// Set assigned user
  void setAssignedTo(String userId) {
    _assignedToUserId = userId;
    notifyListeners();
  }

  /// Set appointment date
  void setAppointmentDate(DateTime? date) {
    _appointmentDate = date;
    if (date != null) {
      _selectedDate = date;
    }
    notifyListeners();
  }

  /// Set appointment time
  void setAppointmentTime(TimeOfDay? time) {
    _appointmentTime = time;
    if (time != null) {
      _selectedTime = time;
    }
    notifyListeners();
  }

  /// Add medication
  void addMedication() {
    int index = _medications.length;
    _medications.add({'name': '', 'dosage': '', 'mealTiming': 'After meal'});
    _medicationControllers[index] = {
      'name': TextEditingController(),
      'dosage': TextEditingController(),
    };
    notifyListeners();
  }

  /// Update medication field
  void updateMedication(int index, String field, String value) {
    if (index >= 0 && index < _medications.length) {
      _medications[index][field] = value;
      notifyListeners();
    }
  }

  /// Remove medication
  void removeMedication(int index) {
    if (index >= 0 && index < _medications.length) {
      _medications.removeAt(index);
      _medicationControllers[index]?['name']?.dispose();
      _medicationControllers[index]?['dosage']?.dispose();
      _medicationControllers.remove(index);
      notifyListeners();
    }
  }

  /// Process OCR from medical card image
  Future<bool> processOCRFromImage(File imageFile) async {
    _isProcessingOCR = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String extractedText = await _ocrService.extractTextFromImage(imageFile);
      Map<String, dynamic> parsedData = _ocrService.parseAppointmentDetails(
        extractedText,
      );

      // Handle Title/Location
      if (parsedData['location'] != null) {
        titleController.text = "Appointment at ${parsedData['location']}";
      } else {
        titleController.text = "Medical Appointment";
      }

      // Handle Date
      if (parsedData['date'] != null) {
        _appointmentDate = parsedData['date'];
        _selectedDate = parsedData['date'];
      } else {
        _appointmentDate = DateTime.now();
        _selectedDate = DateTime.now();
      }

      // Handle Time
      if (parsedData['time'] != null) {
        Map<String, int> timeMap = parsedData['time'] as Map<String, int>;
        _appointmentTime = TimeOfDay(
          hour: timeMap['hour']!,
          minute: timeMap['minute']!,
        );
        _selectedTime = _appointmentTime!;
      } else {
        // Reset to current time if not found
        _appointmentTime = TimeOfDay.now();
        _selectedTime = TimeOfDay.now();
      }

      _isProcessingOCR = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          'OCR failed: ${e.toString().replaceAll('Exception: ', '')}';
      _isProcessingOCR = false;
      notifyListeners();
      return false;
    }
  }

  /// Validate form
  bool _validateForm() {
    String? titleError = _reminderService.validateTitle(titleController.text);
    if (titleError != null) {
      _errorMessage = titleError;
      notifyListeners();
      return false;
    }

    String? descError = _reminderService.validateDescription(
      descriptionController.text,
    );
    if (descError != null) {
      _errorMessage = descError;
      notifyListeners();
      return false;
    }

    if (_assignedToUserId == null) {
      _errorMessage = 'Please select who this reminder is for';
      notifyListeners();
      return false;
    }

    if (_selectedType == 'medication') {
      if (_medications.isEmpty) {
        _errorMessage = 'Please add medication details';
        notifyListeners();
        return false;
      }
      for (var med in _medications) {
        if (med['name'].toString().trim().isEmpty) {
          _errorMessage = 'Medication name is required';
          notifyListeners();
          return false;
        }
      }
    }

    return true;
  }

  /// Save reminder
  Future<bool> saveReminder() async {
    _errorMessage = null;

    if (!_validateForm()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Upload Voice Note if exists
      String? voiceNoteUrl = _existingVoiceNoteUrl;

      if (_voiceNoteFile != null) {
        if (_existingVoiceNoteUrl != null) {
          try {
            await _voiceNoteService.deleteVoiceNote(_existingVoiceNoteUrl!);
          } catch (e) {
            // Ignore deletion errors
          }
        }

        String tempReminderId =
            reminderId ?? DateTime.now().millisecondsSinceEpoch.toString();
        voiceNoteUrl = await _voiceNoteService.uploadVoiceNote(
          file: _voiceNoteFile!,
          groupId: groupId,
          reminderId: tempReminderId,
        );
      }

      // Prepare Type Specific Data
      Map<String, dynamic>? typeSpecificData;
      if (_selectedType == 'medication') {
        typeSpecificData = {
          'medications': _medications,
          'dosageTimesCount': _doseCount,
          'medicationFrequency': _medicationFrequency,
        };
      } else if (_selectedType == 'appointment') {
        typeSpecificData = {
          'appointmentDate': _appointmentDate != null
              ? Timestamp.fromDate(_appointmentDate!)
              : null,
          'appointmentTime': _appointmentTime != null
              ? '${_appointmentTime!.hour}:${_appointmentTime!.minute}'
              : null,
        };
      }

      // Date & Repeat Logic
      DateTime finalScheduledDate = _selectedDate;
      String repeatType = 'once';
      List<int>? repeatDays;

      if (_selectedRepeatDays.isNotEmpty) {
        repeatType = 'specific_days';
        repeatDays = _selectedRepeatDays.toList()..sort();

        if (!_selectedRepeatDays.contains(_selectedDate.weekday)) {
          finalScheduledDate = _findNextValidDate(_selectedDate, repeatDays);
        }
      } else if (!isEditMode && _selectedType == 'medication') {
        repeatType = 'once';
      }

      // cancel old alarm if in edit mode
      if (isEditMode && reminderId != null) {
        await _alarmService.cancelReminderAlarm(reminderId!);
      }

      // If Medication & Create Mode: Loop through dose times and create multiple
      if (_selectedType == 'medication' && !isEditMode) {
        DateTime now = DateTime.now();

        for (TimeOfDay time in _doseTimes) {
          // Calculate the exact date/time for this dose
          DateTime doseDate = finalScheduledDate;
          DateTime doseDateTime = DateTime(
            doseDate.year,
            doseDate.month,
            doseDate.day,
            time.hour,
            time.minute,
          );

          if (doseDateTime.isBefore(now)) {
            // This time has passed for the target date.
            // Move it to the NEXT valid occurrence.

            if (repeatType == 'specific_days' && repeatDays != null) {
              // Find the next allowed day (starts checking from tomorrow)
              doseDate = _findNextValidDate(doseDate, repeatDays);
            } else {
              // If Daily or Once, simply move to Tomorrow
              doseDate = doseDate.add(const Duration(days: 1));
            }
          }

          String timeString =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

          // create reminder and get the ID
          String createdReminderId = await _reminderService.createReminder(
            groupId: groupId,
            createdBy: _currentUserId,
            assignedTo: _assignedToUserId!,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            type: _selectedType,
            scheduledDate: doseDate,
            scheduledTime: timeString,
            repeatType: repeatType,
            repeatDays: repeatDays,
            voiceNoteUrl: voiceNoteUrl,
            typeSpecificData: typeSpecificData,
          );

          // schdule alamr for this medication dose if in future
          DateTime finalDoseDateTime = DateTime(
            doseDate.year,
            doseDate.month,
            doseDate.day,
            time.hour,
            time.minute,
          );

          if (finalDoseDateTime.isAfter(DateTime.now())) {
            await _alarmService.scheduleReminderAlarm(
              reminderId: createdReminderId,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              scheduledTime: finalDoseDateTime,
              reminderType: _selectedType,
            );
          }
        }
      } else {
        TimeOfDay timeToUse = _selectedType == 'medication' && isEditMode
            ? _doseTimes[0]
            : _selectedTime;

        String timeString =
            '${timeToUse.hour.toString().padLeft(2, '0')}:${timeToUse.minute.toString().padLeft(2, '0')}';

        // Calculate final scheduled DateTime
        DateTime finalScheduledDateTime = DateTime(
          finalScheduledDate.year,
          finalScheduledDate.month,
          finalScheduledDate.day,
          timeToUse.hour,
          timeToUse.minute,
        );

        if (isEditMode) {
          // cancel old alarm
          await _alarmService.cancelReminderAlarm(reminderId!);

          // update alarm
          await _reminderService.updateReminder(
            reminderId: reminderId!,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            type: _selectedType,
            scheduledDate: finalScheduledDate,
            scheduledTime: timeString,
            repeatType: repeatType,
            repeatDays: repeatDays,
            voiceNoteUrl: voiceNoteUrl,
            typeSpecificData: typeSpecificData,
          );

          // schedule new alarm if in future
          if (finalScheduledDateTime.isAfter(DateTime.now())) {
            await _alarmService.scheduleReminderAlarm(
              reminderId: reminderId!,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              scheduledTime: finalScheduledDateTime,
              reminderType: _selectedType,
            );
          }
        } else {
          // create new alarm and get the ID
          String createdReminderId = await _reminderService.createReminder(
            groupId: groupId,
            createdBy: _currentUserId,
            assignedTo: _assignedToUserId!,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            type: _selectedType,
            scheduledDate: finalScheduledDate,
            scheduledTime: timeString,
            repeatType: repeatType,
            repeatDays: repeatDays,
            voiceNoteUrl: voiceNoteUrl,
            typeSpecificData: typeSpecificData,
          );

          // shcedule alarm if in future
          if (finalScheduledDateTime.isAfter(DateTime.now())) {
            await _alarmService.scheduleReminderAlarm(
              reminderId: createdReminderId,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              scheduledTime: finalScheduledDateTime,
              reminderType: _selectedType,
            );
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete the current reminder
  Future<bool> deleteReminder() async {
    if (reminderId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _alarmService.cancelReminderAlarm(reminderId!);

      // Delete voice note from storage if it exists
      if (_existingVoiceNoteUrl != null) {
        try {
          await _voiceNoteService.deleteVoiceNote(_existingVoiceNoteUrl!);
        } catch (_) {
          // Ignore errors deleting the file, proceed to delete record
        }
      }

      // Delete from Firestore
      await _reminderService.deleteReminder(reminderId!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper to find next valid date matching the selected days
  DateTime _findNextValidDate(DateTime fromDate, List<int> allowedDays) {
    DateTime tempDate = fromDate;
    for (int i = 0; i < 8; i++) {
      tempDate = tempDate.add(const Duration(days: 1));
      if (allowedDays.contains(tempDate.weekday)) {
        return tempDate;
      }
    }
    return fromDate;
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get elderly members
  List<Map<String, dynamic>> getElderlyMembers() {
    if (_groupData == null) return [];
    List<Map<String, dynamic>> members = _groupData!['members'] ?? [];
    return members.where((m) => m['role'] == 'elderly').toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (var controllers in _medicationControllers.values) {
      controllers['name']?.dispose();
      controllers['dosage']?.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // Setup audio player listeners
  void _setupAudioPlayerListeners() {
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _voiceNotePlaybackPosition = position.inMilliseconds / 1000.0;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _voiceNoteDuration = duration.inMilliseconds / 1000.0;
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        _isPlayingVoiceNote = false;
        _voiceNotePlaybackPosition = 0.0;
        notifyListeners();
      }
    });
  }

  /// Play voice note
  Future<bool> playVoiceNote() async {
    try {
      String? audioPath;

      if (_voiceNoteFile != null) {
        audioPath = _voiceNoteFile!.path;
        await _audioPlayer.play(DeviceFileSource(audioPath));
      } else if (_existingVoiceNoteUrl != null) {
        await _audioPlayer.play(UrlSource(_existingVoiceNoteUrl!));
      } else {
        return false;
      }

      _isPlayingVoiceNote = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isPlayingVoiceNote = false;
      notifyListeners();
      return false;
    }
  }

  /// Pause voice note
  Future<void> pauseVoiceNote() async {
    try {
      await _audioPlayer.pause();
      _isPlayingVoiceNote = false;
      notifyListeners();
    } catch (e) {
      // Ignore
    }
  }

  /// Stop voice note
  Future<void> stopVoiceNote() async {
    try {
      await _audioPlayer.stop();
      _isPlayingVoiceNote = false;
      _voiceNotePlaybackPosition = 0.0;
      notifyListeners();
    } catch (e) {
      // Ignore
    }
  }

  /// Set medication frequency
  void setMedicationFrequency(String frequency) {
    _medicationFrequency = frequency;
    notifyListeners();
  }
}
