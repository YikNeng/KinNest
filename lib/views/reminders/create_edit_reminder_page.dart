import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../viewmodels/create_edit_reminder_viewmodel.dart';

class CreateEditReminderPage extends StatelessWidget {
  final String groupId;
  final String? reminderId;

  const CreateEditReminderPage({
    Key? key,
    required this.groupId,
    this.reminderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          CreateEditReminderViewModel(groupId: groupId, reminderId: reminderId),
      child: const _CreateEditReminderPageBody(),
    );
  }
}

class _CreateEditReminderPageBody extends StatelessWidget {
  const _CreateEditReminderPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CreateEditReminderViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          viewModel.isEditMode ? 'Edit Reminder' : 'Create Reminder',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => _handleBackPress(context, viewModel),
        ),
        actions: [
          if (viewModel.isEditMode && !viewModel.isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 28),
              tooltip: 'Delete Reminder',
              onPressed: () => _handleDelete(context, viewModel),
            ),
          const SizedBox(width: 8), // Right padding
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    if (viewModel.isFetchingData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading reminder data...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Reminder Type'),
          const SizedBox(height: 16),
          _buildReminderTypeSelection(context, viewModel),
          const SizedBox(height: 32),

          _buildCommonFields(context, viewModel),

          const SizedBox(height: 32),
          if (viewModel.selectedType == 'medication') ...[
            _buildMedicationFields(context, viewModel),
            const SizedBox(height: 20),
          ],
          if (viewModel.selectedType == 'appointment')
            _buildAppointmentFields(context, viewModel),

          const SizedBox(height: 32),
          if (viewModel.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(fontSize: 16, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => _handleSave(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      viewModel.isEditMode
                          ? 'Update Reminder'
                          : 'Create Reminder',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: OutlinedButton(
              onPressed: viewModel.isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
      ],
    );
  }

  Widget _buildReminderTypeSelection(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            context: context,
            type: 'Normal',
            icon: Icons.notifications,
            isSelected: viewModel.selectedType == 'normal',
            onTap: () => viewModel.setReminderType('Normal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            context: context,
            type: 'Medication',
            icon: Icons.medication,
            isSelected: viewModel.selectedType == 'medication',
            onTap: () => viewModel.setReminderType('Medication'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            context: context,
            type: 'Appointment',
            icon: Icons.event,
            isSelected: viewModel.selectedType == 'appointment',
            onTap: () => viewModel.setReminderType('Appointment'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required String type,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              type,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonFields(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    bool isMedication = viewModel.selectedType == 'medication';
    // Check if it is an appointment to hide sections
    bool isAppointment = viewModel.selectedType == 'appointment';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Title', required: true),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.titleController,
          style: const TextStyle(fontSize: 18),
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Enter reminder title',
            hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
            counterStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
          ),
          onChanged: (_) => viewModel.clearError(),
        ),
        const SizedBox(height: 20),
        _buildLabel('Description'),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.descriptionController,
          style: const TextStyle(fontSize: 18),
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Add additional details (optional)',
            hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
            counterStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (_) => viewModel.clearError(),
        ),
        const SizedBox(height: 20),
        _buildVoiceNoteSection(context, viewModel),
        const SizedBox(height: 20),

        // --- UPDATED: HIDE DATE/TIME IF APPOINTMENT ---
        if (!isAppointment) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(
                      viewModel.selectedRepeatDays.isNotEmpty
                          ? 'Start Date'
                          : 'Date',
                      required: true,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, viewModel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(viewModel.selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // TIME FIELD logic (Hidden for Medication-Create, and now Hidden for Appointment)
              if (!isMedication || viewModel.isEditMode)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Time', required: true),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, viewModel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                viewModel.selectedTime.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // --- UPDATED: HIDE REPEAT SECTION IF APPOINTMENT ---
        if (!isAppointment) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Repeat'),
              if (viewModel.selectedRepeatDays.isNotEmpty)
                TextButton(
                  onPressed: viewModel.setOneTime,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDaySelector(viewModel),
          if (viewModel.selectedRepeatDays.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                'One-time reminder',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 20),
        ],

        if (viewModel.isCaregiver) _buildAssignedToDropdown(context, viewModel),
      ],
    );
  }

  // --- DAY SELECTOR WIDGET ---
  Widget _buildDaySelector(CreateEditReminderViewModel viewModel) {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        // Weekdays in DateTime are 1 (Mon) to 7 (Sun)
        final int dayValue = index + 1;
        final bool isSelected = viewModel.isDaySelected(dayValue);

        return GestureDetector(
          onTap: () => viewModel.toggleDay(dayValue),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[700] : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- VOICE NOTE WIDGETS ---
  Widget _buildVoiceNoteSection(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    final bool hasVoiceNote =
        viewModel.existingVoiceNoteUrl != null ||
        viewModel.voiceNoteFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Voice Note'),
        const SizedBox(height: 8),

        if (hasVoiceNote)
          _buildVoiceNotePlayback(context, viewModel)
        else if (viewModel.isCaregiver)
          _buildVoiceNoteRecordButton(context, viewModel)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'No voice note',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceNoteRecordButton(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    return InkWell(
      onTap: () => _startRecording(context, viewModel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              'Record Voice Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceNotePlayback(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic, color: Colors.green[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Note Recorded',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    if (viewModel.voiceNoteFile != null)
                      Text(
                        '${_getFileSize(viewModel.voiceNoteFile!)} MB',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDeleteVoiceNote(context, viewModel),
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                iconSize: 26,
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _togglePlayback(context, viewModel),
              icon: Icon(
                viewModel.isPlayingVoiceNote ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              label: Text(
                viewModel.isPlayingVoiceNote ? 'Pause' : 'Play Voice Note',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (viewModel.isPlayingVoiceNote ||
              viewModel.voiceNotePlaybackPosition > 0) ...[
            const SizedBox(height: 12),
            _buildPlaybackProgress(viewModel),
          ],

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _rerecordVoiceNote(context, viewModel),
            icon: Icon(Icons.mic, size: 20),
            label: Text(
              'Re-record',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green[700],
              side: BorderSide(color: Colors.green[700]!, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackProgress(CreateEditReminderViewModel viewModel) {
    double progress = viewModel.voiceNoteDuration > 0
        ? viewModel.voiceNotePlaybackPosition / viewModel.voiceNoteDuration
        : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.green[100],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(viewModel.voiceNotePlaybackPosition),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              _formatDuration(viewModel.voiceNoteDuration),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedToDropdown(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    List<Map<String, dynamic>> elderlyMembers = viewModel.getElderlyMembers();

    if (elderlyMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No elderly members in this group yet. Invite members first.',
                style: TextStyle(fontSize: 15, color: Colors.orange[900]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Assign To', required: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.assignedToUserId,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 32,
                color: Colors.blue[700],
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              items: elderlyMembers.map((member) {
                return DropdownMenuItem<String>(
                  value: member['uid'],
                  child: Text(member['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  viewModel.setAssignedTo(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- REPLACED _buildMedicationFields ---
  Widget _buildMedicationFields(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Medication'),
            if (viewModel.medications.isEmpty)
              ElevatedButton.icon(
                onPressed: viewModel.addMedication,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // --- DOSAGE FREQUENCY (Only in Create Mode) ---
        if (!viewModel.isEditMode) ...[
          _buildLabel('Dosage Times (per day)', required: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: viewModel.decrementDose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.remove, color: Colors.blue[700]),
                  ),
                ),

                Text(
                  '${viewModel.doseCount} time${viewModel.doseCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),

                InkWell(
                  onTap: viewModel.incrementDose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Schedule Times'),
          const SizedBox(height: 8),
          ...List.generate(viewModel.doseTimes.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: viewModel.doseTimes[index],
                  );
                  if (picked != null) {
                    viewModel.setDoseTime(index, picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        viewModel.doseTimes[index].format(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_outlined, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        if (viewModel.medications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No medication added',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add" to add medication details',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          _buildMedicationCard(context, viewModel, 0),
      ],
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
    int index,
  ) {
    Map<String, dynamic> medication = viewModel.medications[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Medicine Name', required: true),
                IconButton(
                  onPressed: () => viewModel.removeMedication(index),
                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // --- FIXED: ADDED onChanged ---
            TextField(
              controller: viewModel.getMedicationController(index, 'name'),
              // This line is crucial: updates the data model as you type
              onChanged: (value) =>
                  viewModel.updateMedication(index, 'name', value),
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'e.g., Aspirin',
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Dosage', required: true),
            const SizedBox(height: 8),

            // --- FIXED: ADDED onChanged ---
            TextField(
              controller: viewModel.getMedicationController(index, 'dosage'),
              // This line is crucial: updates the data model as you type
              onChanged: (value) =>
                  viewModel.updateMedication(index, 'dosage', value),
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'e.g., 100mg',
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Meal Timing', required: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: medication['mealTiming'],
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 28,
                    color: Colors.blue[700],
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  items: viewModel.mealTimingOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      viewModel.updateMedication(index, 'mealTiming', value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... inside _CreateEditReminderPageBody ...

  Widget _buildAppointmentFields(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Appointment Details'),
        const SizedBox(height: 16),

        // Scan Button
        ElevatedButton.icon(
          onPressed: viewModel.isProcessingOCR
              ? null
              : () => _showImageSourceDialog(context, viewModel),
          icon: viewModel.isProcessingOCR
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.camera_alt, size: 24),
          label: Text(
            viewModel.isProcessingOCR
                ? 'Processing...'
                : 'Scan Medical Card (OCR)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Info & Warning Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              // Original Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan your medical appointment card to auto-fill hospital name, date, and time.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // NEW: Warning Text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[800],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please check the date and time again as the scan results may not be 100% accurate.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Appointment Date Field
        _buildLabel('Appointment Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectAppointmentDate(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: viewModel.appointmentDate != null
                    ? Colors.green[300]!
                    : Colors.grey[300]!,
                width: viewModel.appointmentDate != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: viewModel.appointmentDate != null
                  ? Colors.green[50]
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: viewModel.appointmentDate != null
                      ? Colors.green[700]
                      : Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  viewModel.appointmentDate != null
                      ? _formatDate(viewModel.appointmentDate!)
                      : 'Tap to select date',
                  style: TextStyle(
                    fontSize: 18,
                    color: viewModel.appointmentDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                if (viewModel.appointmentDate != null) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Appointment Time Field
        _buildLabel('Appointment Time'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectAppointmentTime(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: viewModel.appointmentTime != null
                    ? Colors.green[300]!
                    : Colors.grey[300]!,
                width: viewModel.appointmentTime != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: viewModel.appointmentTime != null
                  ? Colors.green[50]
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: viewModel.appointmentTime != null
                      ? Colors.green[700]
                      : Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  viewModel.appointmentTime != null
                      ? viewModel.appointmentTime!.format(context)
                      : 'Tap to select time',
                  style: TextStyle(
                    fontSize: 18,
                    color: viewModel.appointmentTime != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                if (viewModel.appointmentTime != null) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- NEW: Helper to show selection dialog ---
  void _showImageSourceDialog(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanMedicalCard(context, viewModel, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanMedicalCard(context, viewModel, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UPDATED: Accepts ImageSource ---
  Future<void> _scanMedicalCard(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source, // Use the selected source
      imageQuality: 80,
    );

    if (image != null && context.mounted) {
      File imageFile = File(image.path);
      bool success = await viewModel.processOCRFromImage(imageFile);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Details extracted! Please verify.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- HELPER METHODS ---

  String _formatDate(DateTime date) {
    List<String> months = [
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
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    double mb = bytes / (1024 * 1024);
    return mb.toStringAsFixed(2);
  }

  String _formatDuration(double seconds) {
    int minutes = seconds.toInt() ~/ 60;
    int remainingSeconds = seconds.toInt() % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      viewModel.setDate(picked);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: viewModel.selectedTime,
    );
    if (picked != null) {
      viewModel.setTime(picked);
    }
  }

  Future<void> _selectAppointmentDate(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.appointmentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      viewModel.setAppointmentDate(picked);
    }
  }

  Future<void> _selectAppointmentTime(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: viewModel.appointmentTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      viewModel.setAppointmentTime(picked);
    }
  }

  Future<void> _startRecording(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VoiceRecordingDialog(
        onSave: (File file) {
          viewModel.setVoiceNoteFile(file);
        },
      ),
    );
  }

  Future<void> _togglePlayback(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    if (viewModel.isPlayingVoiceNote) {
      await viewModel.pauseVoiceNote();
    } else {
      bool success = await viewModel.playVoiceNote();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to play voice note',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _rerecordVoiceNote(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Re-record Voice Note?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will replace your current voice note. Continue?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Re-record',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      viewModel.stopVoiceNote();
      _startRecording(context, viewModel);
    }
  }

  Future<void> _confirmDeleteVoiceNote(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Voice Note?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this voice note?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.removeVoiceNote();
    }
  }

  Future<void> _handleSave(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    FocusScope.of(context).unfocus();
    bool success = await viewModel.saveReminder();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewModel.isEditMode
                      ? 'Reminder updated successfully!'
                      : 'Reminder created successfully!',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) async {
    // 1. Show Confirmation Dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text(
          'Are you sure you want to delete this reminder? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    // 2. Perform Delete if confirmed
    if (shouldDelete == true && context.mounted) {
      bool success = await viewModel.deleteReminder();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 12),
                Text('Reminder deleted successfully'),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Go back to previous screen
      }
    }
  }

  void _handleBackPress(
    BuildContext context,
    CreateEditReminderViewModel viewModel,
  ) {
    bool hasContent =
        viewModel.titleController.text.trim().isNotEmpty ||
        viewModel.descriptionController.text.trim().isNotEmpty ||
        viewModel.medications.isNotEmpty;

    if (hasContent && !viewModel.isLoading) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Discard Changes?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to go back? Your changes will be lost.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pop();
              },
              child: Text(
                'Discard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}

// Keep the VoiceRecordingDialog as it was originally
class _VoiceRecordingDialog extends StatefulWidget {
  final Function(File) onSave;

  const _VoiceRecordingDialog({Key? key, required this.onSave})
    : super(key: key);

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  String? _audioPath;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStart();
  }

  Future<void> _checkPermissionAndStart() async {
    try {
      bool hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Microphone permission is required to record voice notes',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () {
                  // openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _hasPermission = true;
      });

      await _startRecording();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/voice_note_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _audioPath = path;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _startTimer() {
    if (!mounted) return;

    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordDuration++;
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
        }
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _saveRecording() async {
    await _stopRecording();

    if (_audioPath != null) {
      File audioFile = File(_audioPath!);
      if (await audioFile.exists()) {
        int fileSize = await audioFile.length();
        if (fileSize > 0) {
          widget.onSave(audioFile);
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Recording failed: File is empty'),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Recording failed: File not found'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _stopRecording();
    if (_audioPath != null) {
      try {
        File audioFile = File(_audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        print('Error deleting audio file: $e');
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isRecording) {
          return false;
        }
        return true;
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_off,
              size: 80,
              color: _isRecording ? Colors.red[700] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording ? 'Recording...' : 'Recording Stopped',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            if (_isRecording) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRecordingDot(0),
                  const SizedBox(width: 8),
                  _buildRecordingDot(1),
                  const SizedBox(width: 8),
                  _buildRecordingDot(2),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveRecording,
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        double opacity = (value + index * 0.3) % 1.0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[700]!.withOpacity(opacity),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isRecording) {
          setState(() {});
        }
      },
    );
  }
}
