// lib/views/caregiver_reminder_detail_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/caregiver_reminder_detail_viewmodel.dart';

class CaregiverReminderDetailView extends StatelessWidget {
  const CaregiverReminderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverReminderDetailViewModel(),
      child: const CaregiverReminderDetailContent(),
    );
  }
}

class CaregiverReminderDetailContent extends StatelessWidget {
  const CaregiverReminderDetailContent({super.key});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'medicine':
        return const Color(0xFFEF4444);
      case 'appointment':
        return const Color(0xFF3B82F6);
      case 'task':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'medicine':
        return Icons.medication_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      case 'task':
        return Icons.fitness_center_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'medicine':
        return 'Medicine';
      case 'appointment':
        return 'Medical Appointment';
      case 'task':
        return 'Task';
      default:
        return 'Reminder';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaregiverReminderDetailViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.reminder == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            onPressed: () => context.go('/caregiver/reminder'),
          ),
        ),
        body: const Center(
          child: Text('Reminder not found'),
        ),
      );
    }

    final reminder = viewModel.reminder!;
    final typeColor = _getTypeColor(reminder.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.go('/caregiver/reminder'),
        ),
        title: const Text(
          'Reminder Details',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 50),
            onSelected: (String value) {
              viewModel.changeReminderType(value);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'medicine',
                child: Row(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      color: viewModel.currentReminderType == 'medicine'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Medicine',
                      style: TextStyle(
                        color: viewModel.currentReminderType == 'medicine'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1F2937),
                        fontWeight: viewModel.currentReminderType == 'medicine'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (viewModel.currentReminderType == 'medicine')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'appointment',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: viewModel.currentReminderType == 'appointment'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Appointment',
                      style: TextStyle(
                        color: viewModel.currentReminderType == 'appointment'
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF1F2937),
                        fontWeight:
                            viewModel.currentReminderType == 'appointment'
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                    if (viewModel.currentReminderType == 'appointment')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'task',
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      color: viewModel.currentReminderType == 'task'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Task',
                      style: TextStyle(
                        color: viewModel.currentReminderType == 'task'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1F2937),
                        fontWeight: viewModel.currentReminderType == 'task'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (viewModel.currentReminderType == 'task')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getTypeIcon(reminder.type),
                                color: typeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTypeLabel(reminder.type),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: typeColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reminder.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Color(0xFF6C63FF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                viewModel.elderlyName ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Common Fields Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.event,
                          label: 'Date & Time',
                          value: reminder.getFormattedDateTime(),
                          color: typeColor,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: reminder.getDurationText(),
                          color: typeColor,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: reminder.isRecurring
                              ? Icons.repeat
                              : Icons.event_outlined,
                          label: 'Recurrence',
                          value: reminder.getRecurringText(),
                          color: typeColor,
                        ),
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reminder.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Medication Specific Fields
                  if (reminder.type == 'medicine') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medication Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Medicine Name',
                            value: reminder.medicineName ?? 'Not specified',
                            color: typeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.science_outlined,
                            label: 'Dosage',
                            value: reminder.dosage ?? 'Not specified',
                            color: typeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.repeat,
                            label: 'Frequency Per Day',
                            value: '${reminder.frequencyPerDay ?? 0} time(s)',
                            color: typeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.restaurant_outlined,
                            label: 'Meal Timing',
                            value: reminder.mealTiming == 'before'
                                ? 'Before Meal'
                                : reminder.mealTiming == 'after'
                                    ? 'After Meal'
                                    : 'Not specified',
                            color: typeColor,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Medical Appointment Specific Fields
                  if (reminder.type == 'appointment') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Venue / Clinic',
                            value: reminder.venueName ?? 'Not specified',
                            color: typeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.credit_card_outlined,
                            label: 'Appointment Card Scan',
                            value: reminder.hasAppointmentCardScan == true
                                ? 'Card scanned and attached'
                                : 'No card scan available',
                            color: typeColor,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Voice Note Section (Caregiver can record)
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You can record a voice note for the elderly to listen to.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (reminder.hasVoiceNote) ...[
                          // Existing voice note player
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: typeColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      viewModel.toggleVoiceNotePlayback(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: typeColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      viewModel.isPlayingVoiceNote
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Voice note',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        viewModel.isPlayingVoiceNote
                                            ? 'Playing...'
                                            : 'Tap to play',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  reminder.getVoiceNoteDuration(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Record new voice note button
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement actual recording logic
                            if (!viewModel.isRecordingVoiceNote) {
                              viewModel.startRecordingVoiceNote();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Recording voice note (demo)...'),
                                  backgroundColor: Color(0xFFEC4899),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: viewModel.isRecordingVoiceNote
                                  ? const Color(0xFFEF4444).withOpacity(0.1)
                                  : const Color(0xFFEC4899).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: viewModel.isRecordingVoiceNote
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFEC4899),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  viewModel.isRecordingVoiceNote
                                      ? Icons.stop_circle
                                      : Icons.mic,
                                  color: viewModel.isRecordingVoiceNote
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFEC4899),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  viewModel.isRecordingVoiceNote
                                      ? 'Recording...'
                                      : reminder.hasVoiceNote
                                          ? 'Re-record Voice Note'
                                          : 'Record Voice Note',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: viewModel.isRecordingVoiceNote
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFEC4899),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDeleteConfirmation(context, viewModel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/caregiver/reminder/edit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, CaregiverReminderDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Reminder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this reminder? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement actual deletion logic
                viewModel.deleteReminder();
                Navigator.of(dialogContext).pop();
                context.go('/caregiver/reminder');
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
