import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/reminder_alarm_viewmodel.dart';

class ReminderAlarmOverlayPage extends StatelessWidget {
  final String reminderId;

  const ReminderAlarmOverlayPage({Key? key, required this.reminderId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReminderAlarmViewModel(reminderId: reminderId),
      child: const _ReminderAlarmOverlayBody(),
    );
  }
}

class _ReminderAlarmOverlayBody extends StatelessWidget {
  const _ReminderAlarmOverlayBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ReminderAlarmViewModel>(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: viewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SafeArea(
                child: Column(
                  children: [
                    // Timeout indicator
                    _buildTimeoutIndicator(viewModel),

                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Header with icon and title
                            _buildHeader(viewModel),

                            const SizedBox(height: 32),

                            // Description
                            if (viewModel.description.isNotEmpty)
                              _buildDescription(viewModel),

                            // Voice note section
                            if (viewModel.hasVoiceNote) ...[
                              const SizedBox(height: 32),
                              _buildVoiceNoteSection(context, viewModel),
                            ],

                            // Appointment details
                            if (viewModel.reminderType == 'appointment') ...[
                              const SizedBox(height: 32),
                              _buildAppointmentDetails(viewModel),
                            ],

                            // Medication list
                            if (viewModel.reminderType == 'medication' &&
                                viewModel.medications.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildMedicationList(viewModel),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Complete button
                    _buildCompleteButton(context, viewModel),
                  ],
                ),
              ),
      ),
    );
  }

  // Timeout Indicator
  Widget _buildTimeoutIndicator(ReminderAlarmViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.alarm, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            'Auto-dismiss in ${viewModel.formattedTimeRemaining}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(ReminderAlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: viewModel.typeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: viewModel.typeColor, width: 3),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: viewModel.typeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(viewModel.typeIcon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            viewModel.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Description
  Widget _buildDescription(ReminderAlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[600]!, width: 2),
      ),
      child: Text(
        viewModel.description,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, color: Colors.white, height: 1.5),
      ),
    );
  }

  // Voice Note Section
  Widget _buildVoiceNoteSection(
    BuildContext context,
    ReminderAlarmViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[600]!, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Voice Message',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: viewModel.isPlayingVoiceNote
                ? () => viewModel.stopVoiceNote()
                : () => viewModel.playVoiceNote(),
            icon: Icon(
              viewModel.isPlayingVoiceNote ? Icons.stop : Icons.play_arrow,
              size: 40,
            ),
            label: Text(
              viewModel.isPlayingVoiceNote ? 'Stop' : 'Play',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: viewModel.isPlayingVoiceNote
                  ? Colors.red[700]
                  : Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Appointment Details
  Widget _buildAppointmentDetails(ReminderAlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[600]!, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Appointment Time',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.formatScheduledTime(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Medication List
  Widget _buildMedicationList(ReminderAlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[600]!, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medication, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Medications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...viewModel.medications.map((med) => _buildMedicationItem(med)),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    String name = medication['name'] ?? 'Unknown';
    String dosage = medication['dosage'] ?? '';
    String timing = medication['beforeAfterMeal'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (dosage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Dosage: $dosage',
              style: const TextStyle(fontSize: 22, color: Colors.white70),
            ),
          ],
          if (timing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              timing,
              style: const TextStyle(fontSize: 20, color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  // Complete Button
  Widget _buildCompleteButton(
    BuildContext context,
    ReminderAlarmViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 12,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: ElevatedButton(
          onPressed: viewModel.isCompleting
              ? null
              : () async {
                  bool success = await viewModel.completeReminder();
                  if (success && context.mounted) {
                    context.go('/elderly/home');
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: viewModel.isCompleting
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 40),
                    SizedBox(width: 16),
                    Text(
                      'Complete Reminder',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
