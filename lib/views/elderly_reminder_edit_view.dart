import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/elderly_reminder_edit_viewmodel.dart';

class ElderlyReminderEditView extends StatelessWidget {
  const ElderlyReminderEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ElderlyReminderEditViewModel(),
      child: const ElderlyReminderEditContent(),
    );
  }
}

class ElderlyReminderEditContent extends StatelessWidget {
  const ElderlyReminderEditContent({super.key});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'medicine':
        return const Color(0xFFEF4444);
      case 'appointment':
        return const Color(0xFF3B82F6);
      case 'exercise':
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
      case 'exercise':
        return Icons.fitness_center_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'medicine':
        return 'Medicine Reminder';
      case 'appointment':
        return 'Medical Appointment';
      case 'exercise':
        return 'Exercise Reminder';
      default:
        return 'Reminder';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ElderlyReminderEditViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final typeColor = _getTypeColor(viewModel.reminderType);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Reminder',
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
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(viewModel.reminderType),
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
                                _getTypeLabel(viewModel.reminderType),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Edit your reminder details',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
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
                        ),
                        const SizedBox(height: 16),

                        // Date & Time
                        _buildDateTimePicker(context, viewModel, typeColor),
                        const SizedBox(height: 16),

                        // Duration
                        _buildDurationSelector(viewModel, typeColor),
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
                  if (viewModel.reminderType == 'medicine') ...[
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
                  if (viewModel.reminderType == 'appointment') ...[
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
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: viewModel.hasAppointmentCardScan
                                  ? typeColor.withOpacity(0.1)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: viewModel.hasAppointmentCardScan
                                    ? typeColor.withOpacity(0.3)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  viewModel.hasAppointmentCardScan
                                      ? Icons.check_circle
                                      : Icons.credit_card_outlined,
                                  color: viewModel.hasAppointmentCardScan
                                      ? typeColor
                                      : const Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.hasAppointmentCardScan
                                        ? 'Appointment card scanned and attached'
                                        : 'No appointment card scan available',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: viewModel.hasAppointmentCardScan
                                          ? typeColor
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Voice Note Section
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
                          'You cannot record voice notes, but you can listen to notes from your caregiver.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (viewModel.hasVoiceNote)
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
                                  viewModel.getVoiceNoteDuration(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mic_off_outlined,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'No voice note available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
                    onTap: () => context.pop(),
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
                          'Save Changes',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
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
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(BuildContext context,
      ElderlyReminderEditViewModel viewModel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDateTime(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
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

  Widget _buildDurationSelector(
      ElderlyReminderEditViewModel viewModel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
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
              Icon(Icons.schedule, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatDuration(viewModel.durationMinutes),
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
                      if (viewModel.durationMinutes > 5) {
                        viewModel.setDuration(viewModel.durationMinutes - 5);
                      }
                    },
                    icon: Icon(Icons.remove_circle_outline, color: color),
                  ),
                  IconButton(
                    onPressed: () {
                      viewModel.setDuration(viewModel.durationMinutes + 5);
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

  Widget _buildRecurrenceToggle(
      ElderlyReminderEditViewModel viewModel, Color color) {
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
      ElderlyReminderEditViewModel viewModel, Color color) {
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
      ElderlyReminderEditViewModel viewModel, Color color) {
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
      ElderlyReminderEditViewModel viewModel, Color color) {
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

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $mins min';
  }

  Future<void> _selectDateTime(
      BuildContext context, ElderlyReminderEditViewModel viewModel) async {
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
      BuildContext context, ElderlyReminderEditViewModel viewModel) async {
    final validationError = viewModel.validateFields();

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await viewModel.saveChanges();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // Navigate back to detail page
      context.go('/elderly/reminder/detail');
    }
  }
}
