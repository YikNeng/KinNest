import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/caregiver_reminder_viewmodel.dart';

class CaregiverReminderListPage extends StatelessWidget {
  const CaregiverReminderListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverReminderViewModel(),
      child: const _CaregiverReminderListPageBody(),
    );
  }
}

class _CaregiverReminderListPageBody extends StatelessWidget {
  const _CaregiverReminderListPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CaregiverReminderViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CaregiverReminderViewModel viewModel,
  ) {
    // Loading state
    if (viewModel.isLoading && viewModel.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading reminders...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // No groups state
    if (viewModel.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No Groups Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create a care group to start managing reminders',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Content
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: Column(
        children: [
          // Group Selector
          _buildGroupSelector(context, viewModel),

          // Error Message
          if (viewModel.errorMessage != null) _buildErrorMessage(viewModel),

          // Reminder List
          Expanded(
            child: viewModel.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue[700],
                      strokeWidth: 4,
                    ),
                  )
                : _buildReminderList(context, viewModel),
          ),
        ],
      ),
    );
  }

  // Group Selector Dropdown
  Widget _buildGroupSelector(
    BuildContext context,
    CaregiverReminderViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.blue[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: viewModel.selectedGroup,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blue[700],
                  size: 32,
                ),
                items: viewModel.groups.map((Map<String, dynamic> group) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: group,
                    child: Text(
                      group['groupName'] ?? 'Unnamed Group',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? newGroup) {
                  if (newGroup != null) {
                    viewModel.selectGroup(newGroup);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(CaregiverReminderViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[900],
              ),
            ),
          ),
          IconButton(
            onPressed: viewModel.clearError,
            icon: Icon(Icons.close, color: Colors.red[700]),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // Reminder List
  Widget _buildReminderList(
    BuildContext context,
    CaregiverReminderViewModel viewModel,
  ) {
    if (viewModel.reminders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.reminders.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> reminder = viewModel.reminders[index];
        return _buildReminderCard(context, viewModel, reminder);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Upcoming Reminders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No upcoming reminders for this group',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    CaregiverReminderViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    String reminderType = reminder['reminderType'] ?? 'normal';
    IconData icon = viewModel.getReminderIcon(reminderType);
    Color color = viewModel.getReminderColor(reminderType);

    String? assignedTo = reminder['assignedTo'];
    String elderlyName = assignedTo != null
        ? viewModel.getElderlyName(assignedTo)
        : 'Unassigned';

    Timestamp scheduledTime = reminder['scheduledTime'];
    String scheduledTimeStr = viewModel.formatScheduledTime(scheduledTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to reminder detail/edit page
            String reminderId = reminder['reminderId'];
            context.push('/caregiver/reminder/detail/$reminderId');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reminder Title
                      Text(
                        reminder['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Elderly Name
                      Row(
                        children: [
                          Icon(Icons.person, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              elderlyName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Scheduled Time
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              scheduledTimeStr,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Reminder Type Badge
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          reminderType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
