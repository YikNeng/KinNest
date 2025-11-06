// lib/views/caregiver_reminder_create_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/caregiver_reminder_create_viewmodel.dart';
import '../models/reminder_model.dart';

class CaregiverReminderCreateView extends StatelessWidget {
  const CaregiverReminderCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverReminderCreateViewModel(),
      child: const CaregiverReminderCreateContent(),
    );
  }
}

class CaregiverReminderCreateContent extends StatelessWidget {
  const CaregiverReminderCreateContent({super.key});

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return const Color(0xFFEF4444);
      case ReminderType.appointment:
        return const Color(0xFF3B82F6);
      case ReminderType.task:
        return const Color(0xFF10B981);
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Icons.medication_outlined;
      case ReminderType.appointment:
        return Icons.calendar_today_outlined;
      case ReminderType.task:
        return Icons.task_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaregiverReminderCreateViewModel>();
    final typeColor = _getTypeColor(viewModel.selectedType);

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
          'Create Reminder',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Reminder Type Selection
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
                          'Reminder Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: ReminderType.values.map((type) {
                            final isSelected = viewModel.selectedType == type;
                            final color = _getTypeColor(type);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => viewModel.setReminderType(type),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.1)
                                        : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getTypeIcon(type),
                                        color: isSelected
                                            ? color
                                            : const Color(0xFF6B7280),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        type.displayName.split(' ').first,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? color
                                              : const Color(0xFF6B7280),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Common Fields
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

                        // Title
                        _buildTextField(
                          label: 'Title',
                          controller: viewModel.titleController,
                          icon: Icons.title,
                          color: typeColor,
                          isRequired: true,
                          errorText: viewModel.titleError,
                        ),
                        const SizedBox(height: 16),

                        // Date & Time
                        _buildDateTimePicker(context, viewModel, typeColor),
                        if (viewModel.dateTimeError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            viewModel.dateTimeError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Duration
                        _buildTextField(
                          label: 'Duration (minutes)',
                          controller: viewModel.durationController,
                          icon: Icons.schedule,
                          color: typeColor,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Recurrence Toggle
                        _buildRecurrenceToggle(viewModel, typeColor),

                        if (viewModel.isRecurring) ...[
                          const SizedBox(height: 12),
                          _buildRecurringPatternSelector(viewModel, typeColor),
                        ],

                        const SizedBox(height: 16),

                        // Description
                        _buildTextField(
                          label: 'Description / Notes',
                          controller: viewModel.descriptionController,
                          icon: Icons.notes,
                          color: typeColor,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  // Medication Specific Fields
                  if (viewModel.selectedType == ReminderType.medication) ...[
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
                          _buildTextField(
                            label: 'Medicine Name',
                            controller: viewModel.medicineNameController,
                            icon: Icons.medical_services_outlined,
                            color: typeColor,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Dosage',
                            controller: viewModel.dosageController,
                            icon: Icons.science_outlined,
                            color: typeColor,
                          ),
                          const SizedBox(height: 16),
                          _buildFrequencySelector(viewModel, typeColor),
                          const SizedBox(height: 16),
                          _buildMealTimingSelector(viewModel, typeColor),
                        ],
                      ),
                    ),
                  ],

                  // Appointment Specific Fields
                  if (viewModel.selectedType == ReminderType.appointment) ...[
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

                          _buildTextField(
                            label: 'Venue / Clinic Name',
                            controller: viewModel.venueController,
                            icon: Icons.location_on_outlined,
                            color: typeColor,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),

                          // Scan Appointment Card Button
                          GestureDetector(
                            onTap: () {
                              // TODO: Future integration point - Camera/Scanner for appointment card
                              viewModel.scanAppointmentCard();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Appointment card scan feature coming soon'),
                                  backgroundColor: Color(0xFF3B82F6),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: viewModel.hasAppointmentCardScan
                                    ? typeColor.withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: viewModel.hasAppointmentCardScan
                                      ? typeColor
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    viewModel.hasAppointmentCardScan
                                        ? Icons.check_circle
                                        : Icons.camera_alt_outlined,
                                    color: viewModel.hasAppointmentCardScan
                                        ? typeColor
                                        : const Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    viewModel.hasAppointmentCardScan
                                        ? 'Appointment Card Scanned'
                                        : 'Scan Appointment Card',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: viewModel.hasAppointmentCardScan
                                          ? typeColor
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        const Text(
                          'Record a voice note for the elderly to listen to.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Record Voice Note Button
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement actual recording logic
                            if (!viewModel.isRecordingVoiceNote &&
                                !viewModel.hasVoiceNote) {
                              viewModel.startRecordingVoiceNote();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recording voice note...'),
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

                        // Play Voice Note Button (only visible when recorded)
                        if (viewModel.hasVoiceNote) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // TODO: Implement actual playback logic
                                    viewModel.playVoiceNote();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Playing voice note...'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_arrow,
                                          color: Color(0xFF10B981),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Play',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => viewModel.removeVoiceNote(),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    onTap: () => context.go('/caregiver/reminder'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleSave(context, viewModel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Create Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    bool isRequired = false,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(BuildContext context,
      CaregiverReminderCreateViewModel viewModel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDateTime(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: viewModel.dateTimeError != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(viewModel.selectedDateTime),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceToggle(
      CaregiverReminderCreateViewModel viewModel, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, color: color, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recurring Reminder',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Switch(
            value: viewModel.isRecurring,
            onChanged: (value) => viewModel.setIsRecurring(value),
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringPatternSelector(
      CaregiverReminderCreateViewModel viewModel, Color color) {
    return Wrap(
      spacing: 8,
      children: ['Daily', 'Weekly', 'Monthly'].map((pattern) {
        final isSelected = viewModel.recurringPattern == pattern;
        return GestureDetector(
          onTap: () => viewModel.setRecurringPattern(pattern),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? color.withOpacity(0.1) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              pattern,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector(
      CaregiverReminderCreateViewModel viewModel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency Per Day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${viewModel.frequencyPerDay} time(s) per day',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (viewModel.frequencyPerDay > 1) {
                        viewModel
                            .setFrequencyPerDay(viewModel.frequencyPerDay - 1);
                      }
                    },
                    icon: Icon(Icons.remove_circle_outline, color: color),
                  ),
                  IconButton(
                    onPressed: () {
                      viewModel
                          .setFrequencyPerDay(viewModel.frequencyPerDay + 1);
                    },
                    icon: Icon(Icons.add_circle_outline, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimingSelector(
      CaregiverReminderCreateViewModel viewModel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Timing',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.setMealTiming('before'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: viewModel.mealTiming == 'before'
                        ? color.withOpacity(0.1)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.mealTiming == 'before'
                          ? color
                          : const Color(0xFFE5E7EB),
                      width: viewModel.mealTiming == 'before' ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Before Meal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: viewModel.mealTiming == 'before'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: viewModel.mealTiming == 'before'
                            ? color
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.setMealTiming('after'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: viewModel.mealTiming == 'after'
                        ? color.withOpacity(0.1)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.mealTiming == 'after'
                          ? color
                          : const Color(0xFFE5E7EB),
                      width: viewModel.mealTiming == 'after' ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'After Meal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: viewModel.mealTiming == 'after'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: viewModel.mealTiming == 'after'
                            ? color
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
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

  Future<void> _selectDateTime(
      BuildContext context, CaregiverReminderCreateViewModel viewModel) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(viewModel.selectedDateTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        viewModel.setDateTime(newDateTime);
      }
    }
  }

  Future<void> _handleSave(
      BuildContext context, CaregiverReminderCreateViewModel viewModel) async {
    // TODO: Future integration point - save to backend and handle response
    final success = await viewModel.saveReminder();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder Created'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // Navigate back to reminder list
      context.go('/caregiver/reminder');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }
}
