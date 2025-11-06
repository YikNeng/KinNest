class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String type;
  final bool isRecurring;
  final String? recurringPattern;
  final int? durationMinutes;

  // Medication specific fields
  final String? medicineName;
  final String? dosage;
  final int? frequencyPerDay;
  final String? mealTiming; // 'before' or 'after'

  // Medical Appointment specific fields
  final String? venueName;
  final bool? hasAppointmentCardScan;

  // Voice note
  final bool hasVoiceNote;
  final String? voiceNoteUrl;
  final int? voiceNoteDurationSeconds;

  ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.isRecurring = false,
    this.recurringPattern,
    this.durationMinutes,
    this.medicineName,
    this.dosage,
    this.frequencyPerDay,
    this.mealTiming,
    this.venueName,
    this.hasAppointmentCardScan,
    this.hasVoiceNote = false,
    this.voiceNoteUrl,
    this.voiceNoteDurationSeconds,
  });

  String getFormattedTime() {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String getFormattedDate() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  String getFormattedDateTime() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute';
  }

  String getRecurringText() {
    if (!isRecurring) return 'One-time';
    return recurringPattern ?? 'Recurring';
  }

  String getDurationText() {
    if (durationMinutes == null) return 'Not specified';
    if (durationMinutes! < 60) return '$durationMinutes minutes';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (minutes == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
  }

  String getVoiceNoteDuration() {
    if (voiceNoteDurationSeconds == null) return '0:00';
    final minutes = voiceNoteDurationSeconds! ~/ 60;
    final seconds = voiceNoteDurationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum ReminderType { medication, appointment, task }

extension ReminderTypeExtension on ReminderType {
  String get value {
    switch (this) {
      case ReminderType.medication:
        return 'medicine';
      case ReminderType.appointment:
        return 'appointment';
      case ReminderType.task:
        return 'task';
    }
  }

  String get displayName {
    switch (this) {
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.appointment:
        return 'Medical Appointment';
      case ReminderType.task:
        return 'Normal Task';
    }
  }
}
