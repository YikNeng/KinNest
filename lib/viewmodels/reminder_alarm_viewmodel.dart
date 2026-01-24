import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../services/alarm_service.dart';
import '../services/reminder_service.dart'; //

class ReminderAlarmViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AlarmService _alarmService = AlarmService();
  final ReminderService _reminderService =
      ReminderService(); // Use the shared service
  final AudioPlayer _audioPlayer = AudioPlayer();

  final String reminderId;

  // State
  Map<String, dynamic>? _reminderData;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  bool _isPlayingVoiceNote = false;
  bool _isCompleting = false;
  int _secondsRemaining = 120; // 2 minutes auto-dismiss
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  bool _isDisposed = false;
  bool _shouldClose = false;

  // Getters
  Map<String, dynamic>? get reminderData => _reminderData;
  List<Map<String, dynamic>> get medications => _medications;
  bool get isLoading => _isLoading;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;
  bool get isCompleting => _isCompleting;
  int get secondsRemaining => _secondsRemaining;
  bool get shouldClose => _shouldClose;
  String get formattedTimeRemaining {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Reminder details
  String get title => _reminderData?['title'] ?? 'Reminder';
  String get description => _reminderData?['description'] ?? '';
  String get reminderType => _reminderData?['type'] ?? 'normal';
  String? get voiceNoteUrl => _reminderData?['voiceNoteUrl'];
  bool get hasVoiceNote => voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty;
  Timestamp? get scheduledTime => _reminderData?['scheduledTime'];

  IconData get typeIcon {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return Colors.red;
      case 'appointment':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  ReminderAlarmViewModel({required this.reminderId}) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;
    await _loadReminderData();
    _startAutoTimeout();
    _startVibration();
  }

  Future<void> _loadReminderData() async {
    if (_isDisposed) return;

    try {
      DocumentSnapshot reminderDoc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (!reminderDoc.exists) {
        if (!_isDisposed) {
          _isLoading = false;
          notifyListeners();
        }
        return;
      }

      _reminderData = reminderDoc.data() as Map<String, dynamic>;

      if (reminderType.toLowerCase() == 'medication') {
        await _loadMedications();
      }

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadMedications() async {
    // ... (Keep existing medication loading logic) ...
    if (_isDisposed) return;
    try {
      // Logic from previous version...
      if (_reminderData?['typeSpecificData'] != null &&
          _reminderData!['typeSpecificData']['medications'] != null) {
        _medications = List<Map<String, dynamic>>.from(
          _reminderData!['typeSpecificData']['medications'],
        );
      }
    } catch (e) {
      print('Error loading medications: $e');
    }
  }

  // --- TIMER LOGIC ---

  void _startAutoTimeout() {
    // Countdown for UI
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _secondsRemaining--;
      notifyListeners();

      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });

    // Actual Logic Timeout (2 Minutes)
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!_isDisposed) {
        _handleTimeout();
      }
    });
  }

  /// Triggered when 2 minutes passes without user action
  Future<void> _handleTimeout() async {
    if (_isDisposed) return;

    try {
      await _stopVibration();
      await stopVoiceNote();

      // MARK AS OVERDUE IN DATABASE
      // This ensures it shows up as 'Overdue' in the history lists
      await _firestore.collection('reminders').doc(reminderId).update({
        'status': 'overdue',
        'isCompleted': false, // Explicitly ensure it's not done
        'overdueAt': FieldValue.serverTimestamp(),
      });

      // Cancel the notification/alarm so it stops ringing
      await _alarmService.cancelReminderAlarm(reminderId);

      _shouldClose = true;
      notifyListeners(); // Tell the View to rebuild/check this flag
    } catch (e) {
      print('Error handling timeout: $e');
    }
  }

  // --- ACTION LOGIC ---

  /// Complete reminder using the CENTRAL SERVICE LOGIC
  Future<bool> completeReminder() async {
    if (_isDisposed || _isCompleting) return false;

    _isCompleting = true;
    notifyListeners();

    try {
      await _stopVibration();
      if (_isPlayingVoiceNote) await stopVoiceNote();

      // 1. Prepare Data for Service
      String title = _reminderData?['title'] ?? 'Untitled';

      // Robust Date Parsing
      DateTime currentDueDate;
      if (_reminderData?['scheduledTime'] is Timestamp) {
        currentDueDate = (_reminderData?['scheduledTime'] as Timestamp)
            .toDate();
      } else {
        currentDueDate = DateTime.now();
      }

      String repeatInterval = _reminderData?['repeatType'] ?? 'once';
      List<dynamic>? rawDays = _reminderData?['repeatDays'];
      List<int>? repeatDays = rawDays != null ? List<int>.from(rawDays) : null;

      // 2. CALL THE SERVICE (Crucial Fix: Matches ReminderViewModel logic)
      // This handles: marking as done, moving to history, AND creating the next recurring task
      await _reminderService.completeRecurringTask(
        reminderId: reminderId,
        title: title,
        currentDueDate: currentDueDate,
        repeatInterval: repeatInterval,
        repeatDays: repeatDays,
      );

      // 3. Cancel the Alarm Notification
      await _alarmService.cancelReminderAlarm(reminderId);

      // 4. Cleanup Timers
      _timeoutTimer?.cancel();
      _countdownTimer?.cancel();

      if (!_isDisposed) {
        _isCompleting = false;
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error completing reminder: $e');
      if (!_isDisposed) {
        _isCompleting = false;
        notifyListeners();
      }
      return false;
    }
  }

  // --- AUDIO & VIBRATION ---

  Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000], repeat: 0);
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  Future<void> _stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<void> playVoiceNote() async {
    if (_isDisposed || !hasVoiceNote || _isPlayingVoiceNote) return;
    try {
      _isPlayingVoiceNote = true;
      notifyListeners();
      await _audioPlayer.play(UrlSource(voiceNoteUrl!));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (!_isDisposed) {
          _isPlayingVoiceNote = false;
          notifyListeners();
        }
      });
    } catch (_) {
      _isPlayingVoiceNote = false;
      notifyListeners();
    }
  }

  Future<void> stopVoiceNote() async {
    try {
      await _audioPlayer.stop();
      _isPlayingVoiceNote = false;
      notifyListeners();
    } catch (_) {}
  }

  String formatScheduledTime() {
    if (scheduledTime == null) return '';
    DateTime dateTime = scheduledTime!.toDate();
    return '${dateTime.day}/${dateTime.month} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _stopVibration();
    super.dispose();
  }
}
