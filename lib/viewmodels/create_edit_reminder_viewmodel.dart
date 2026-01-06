import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart'; // This imports TimeOfDay
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reminder_service.dart';
import '../services/voice_note_service.dart'; // Updated import
import '../services/ocr_service.dart';
import '../services/group_service.dart';

class CreateEditReminderViewModel extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final VoiceNoteService _voiceNoteService = VoiceNoteService(); // Updated
  final OCRService _ocrService = OCRService();
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final String groupId;
  final String? reminderId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // State variables
  String _selectedType = 'normal';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedRepeatType = 'once';
  String _medicationFrequency = 'once';
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
  String? _assignedToUserId; // Made public accessible
  bool _isPlayingVoiceNote = false;
  double _voiceNotePlaybackPosition = 0.0;
  double _voiceNoteDuration = 0.0;

  String get medicationFrequency => _medicationFrequency;
  // Add these getters
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  double get voiceNotePlaybackPosition => _voiceNotePlaybackPosition;
  double get voiceNoteDuration => _voiceNoteDuration;

  // Medication controllers for each medication
  Map<int, Map<String, TextEditingController>> _medicationControllers = {};

  // Reminder types
  final List<String> reminderTypes = ['Normal', 'Medication', 'Appointment'];

  // Repeat options
  final List<String> repeatOptions = [
    'One-time',
    'Daily',
    'Weekly',
    'Monthly',
    'Every 2 days',
    'Every 3 days',
    'Every 4 days',
    'Every 5 days',
    'Every 6 days',
  ];

  // Medication frequency options
  final List<String> frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
  ];

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
  String get selectedRepeatType => _selectedRepeatType;
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
    _selectedType = reminderData['type'] ?? 'normal';
    _assignedToUserId = reminderData['assignedTo'];

    Timestamp scheduledTimestamp = reminderData['scheduledTime'];
    DateTime scheduledDateTime = scheduledTimestamp.toDate();
    _selectedDate = scheduledDateTime;
    _selectedTime = TimeOfDay(
      hour: scheduledDateTime.hour,
      minute: scheduledDateTime.minute,
    );

    _selectedRepeatType = reminderData['repeatType'] ?? 'once';
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
    }
    if (_selectedType != 'appointment') {
      _appointmentDate = null;
      _appointmentTime = null;
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
    notifyListeners();
  }

  /// Set repeat type
  void setRepeatType(String type) {
    _selectedRepeatType = _convertRepeatTypeToFirestoreFormat(type);
    notifyListeners();
  }

  /// Convert UI repeat type to Firestore format
  String _convertRepeatTypeToFirestoreFormat(String uiType) {
    switch (uiType) {
      case 'One-time':
        return 'once';
      case 'Daily':
        return 'daily';
      case 'Weekly':
        return 'weekly';
      case 'Monthly':
        return 'monthly';
      case 'Every 2 days':
        return 'every_2_days';
      case 'Every 3 days':
        return 'every_3_days';
      case 'Every 4 days':
        return 'every_4_days';
      case 'Every 5 days':
        return 'every_5_days';
      case 'Every 6 days':
        return 'every_6_days';
      default:
        return 'once';
    }
  }

  /// Set voice note file
  void setVoiceNoteFile(File? file) {
    _voiceNoteFile = file;
    notifyListeners();
  }

  /// Remove voice note (override existing method to also stop playback)
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
    _medications.add({
      'name': '',
      'dosage': '',
      'frequency': 'Once daily',
      'mealTiming': 'After meal',
    });
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

      if (parsedData['date'] != null) {
        _appointmentDate = parsedData['date'];
        _selectedDate = parsedData['date'];
      }

      if (parsedData['time'] != null) {
        // Convert Map to TimeOfDay
        Map<String, int> timeMap = parsedData['time'] as Map<String, int>;
        _appointmentTime = TimeOfDay(
          hour: timeMap['hour']!,
          minute: timeMap['minute']!,
        );
        _selectedTime = _appointmentTime!;
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
        _errorMessage = 'Please add medication';
        notifyListeners();
        return false;
      }
      // Ensure only one medication
      if (_medications.length > 1) {
        _errorMessage = 'Only one medication per reminder';
        notifyListeners();
        return false;
      }
      for (var med in _medications) {
        if (med['name'].toString().trim().isEmpty) {
          _errorMessage = 'Please fill in medication name';
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

      Map<String, dynamic>? typeSpecificData;
      if (_selectedType == 'medication') {
        typeSpecificData = {
          'medications': _medications, // Keep your existing
          'medicationFrequency': _medicationFrequency, // ADD this
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

      String timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      if (isEditMode) {
        await _reminderService.updateReminder(
          reminderId: reminderId!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          type: _selectedType,
          scheduledDate: _selectedDate,
          scheduledTime: timeString,
          repeatType: _selectedRepeatType,
          voiceNoteUrl: voiceNoteUrl,
          typeSpecificData: typeSpecificData,
        );
      } else {
        await _reminderService.createReminder(
          groupId: groupId,
          createdBy: _currentUserId,
          assignedTo: _assignedToUserId!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          type: _selectedType,
          scheduledDate: _selectedDate,
          scheduledTime: timeString,
          repeatType: _selectedRepeatType,
          voiceNoteUrl: voiceNoteUrl,
          typeSpecificData: typeSpecificData,
        );
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
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (var controllers in _medicationControllers.values) {
      controllers['name']?.dispose();
      controllers['dosage']?.dispose();
    }
    _audioPlayer.dispose();
  }

  // Setup audio player listeners
  void _setupAudioPlayerListeners() {
    // Listen to playback position
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _voiceNotePlaybackPosition = position.inMilliseconds / 1000.0;
      notifyListeners();
    });

    // Listen to duration
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _voiceNoteDuration = duration.inMilliseconds / 1000.0;
      notifyListeners();
    });

    // Listen to player state
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

      // Determine audio source
      if (_voiceNoteFile != null) {
        // Play from local file
        audioPath = _voiceNoteFile!.path;
        await _audioPlayer.play(DeviceFileSource(audioPath));
      } else if (_existingVoiceNoteUrl != null) {
        // Play from URL
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

  /// NEW METHOD: Set medication frequency
  void setMedicationFrequency(String frequency) {
    _medicationFrequency = frequency;
    notifyListeners();
  }

  String _getTimeLabel(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
}
