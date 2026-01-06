import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/reminder_list_viewmodel.dart';

class ReminderListPage extends StatelessWidget {
  final String groupId;

  const ReminderListPage({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReminderListViewModel(groupId: groupId),
      child: const _ReminderListPageBody(),
    );
  }
}

class _ReminderListPageBody extends StatelessWidget {
  const _ReminderListPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ReminderListViewModel>(context);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterTabs(context, viewModel),
        ),
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: viewModel.isCaregiver
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateReminder(context, viewModel),
              backgroundColor: Colors.blue[700],
              icon: const Icon(Icons.add, size: 28),
              label: const Text(
                'Add Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  // Filter tabs
  Widget _buildFilterTabs(
    BuildContext context,
    ReminderListViewModel viewModel,
  ) {
    return Container(
      color: Colors.blue[700],
      child: Row(
        children: [
          _buildFilterTab(
            context,
            viewModel,
            'All',
            'all',
            viewModel.reminders.length,
          ),
          _buildFilterTab(
            context,
            viewModel,
            'Pending',
            'pending',
            viewModel.pendingCount,
          ),
          _buildFilterTab(
            context,
            viewModel,
            'Completed',
            'completed',
            viewModel.completedCount,
          ),
          _buildFilterTab(
            context,
            viewModel,
            'Overdue',
            'overdue',
            viewModel.overdueCount,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    ReminderListViewModel viewModel,
    String label,
    String mode,
    int count,
  ) {
    bool isSelected = viewModel.filterMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.setFilterMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReminderListViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
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

    // Error state
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => viewModel.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (!viewModel.hasReminders || viewModel.reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                viewModel.filterMode == 'all'
                    ? 'No Reminders Yet'
                    : 'No ${viewModel.filterMode} reminders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.isCaregiver
                    ? 'Create your first reminder to\nhelp manage care tasks'
                    : 'No reminders have been\nassigned to you yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (viewModel.isCaregiver) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () =>
                      _navigateToCreateReminder(context, viewModel),
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text(
                    'Create Reminder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Reminders list
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.reminders.length,
        itemBuilder: (context, index) {
          final reminder = viewModel.reminders[index];
          return _buildReminderCard(context, viewModel, reminder);
        },
      ),
    );
  }

  // Individual reminder card
  // Updated _buildReminderCard with larger fonts and assigned user display
  Widget _buildReminderCard(
    BuildContext context,
    ReminderListViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    String reminderId = reminder['reminderId'];
    String title = reminder['title'] ?? 'Untitled';
    String? description = reminder['description'];
    Timestamp scheduledTime = reminder['scheduledTime'];
    bool isCompleted = viewModel.isReminderCompleted(reminder);
    bool isOverdue = viewModel.isOverdue(reminder);
    bool isRecurring = viewModel.isRecurringReminder(reminder);
    String typeIcon = viewModel.getReminderTypeIcon(reminder);
    Color typeColor = viewModel.getReminderTypeColor(reminder);
    int completionCount = viewModel.getCompletionCount(reminder);
    DateTime? lastCompletion = viewModel.getLastCompletionDate(reminder);
    bool isHistoryExpanded = viewModel.isHistoryExpanded(reminderId);

    // Get assigned user info
    String assignedUserName = viewModel.getAssignedUserName(reminder);
    String assignedUserInitials = viewModel.getAssignedUserInitials(reminder);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue && !isCompleted
              ? Colors.red.shade200
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: viewModel.isCaregiver
            ? () => _navigateToEditReminder(context, viewModel, reminderId)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon (larger)
                  Container(
                    width: 60, // Increased from 50
                    height: 60, // Increased from 50
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        typeIcon,
                        style: const TextStyle(
                          fontSize: 32,
                        ), // Increased from 28
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and assigned user
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (larger font)
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22, // Increased from 18
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Assigned user (caregiver view only)
                        if (viewModel.isCaregiver) ...[
                          Row(
                            children: [
                              // User avatar
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    assignedUserInitials,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'For $assignedUserName',
                                  style: TextStyle(
                                    fontSize: 16, // Larger font
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),

                  // Checkbox (Elderly) or Status (Caregiver)
                  if (viewModel.isElderly)
                    Transform.scale(
                      scale: 1.3, // Larger checkbox
                      child: Checkbox(
                        value: isCompleted,
                        onChanged: isRecurring && isCompleted
                            ? null
                            : (value) => _toggleCompletion(
                                context,
                                viewModel,
                                reminder,
                              ),
                        activeColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  else if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      size: 36, // Increased from 32
                      color: Colors.green[700],
                    ),
                ],
              ),

              const SizedBox(height: 16), // Increased spacing
              // Time (larger font)
              Row(
                children: [
                  Icon(
                    isOverdue && !isCompleted
                        ? Icons.warning_amber
                        : Icons.schedule,
                    size: 20, // Increased from 16
                    color: isOverdue && !isCompleted
                        ? Colors.red[700]
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 10), // Increased spacing
                  Expanded(
                    child: Text(
                      viewModel.formatReminderTime(scheduledTime),
                      style: TextStyle(
                        fontSize: 17, // Increased from 14
                        color: isOverdue && !isCompleted
                            ? Colors.red[700]
                            : Colors.grey[700],
                        fontWeight: isOverdue && !isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              // Description (larger font)
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 14), // Increased spacing
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 17, // Increased from 15
                    color: Colors.grey[700],
                    height: 1.5, // Increased line height
                  ),
                  maxLines: 3, // Increased from 2
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Recurring indicator
              if (isRecurring) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ), // Increased
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 18, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'RECURRING',
                        style: TextStyle(
                          fontSize: 14, // Increased from 12
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Overdue badge
              if (isOverdue && !isCompleted) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 14, // Increased from 12
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Completed badge
              if (isCompleted) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      if (lastCompletion != null) ...[
                        Text(
                          ' • ${viewModel.formatCompletionDate(Timestamp.fromDate(lastCompletion))}',
                          style: TextStyle(
                            fontSize: 14, // Increased from 12
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Completion history (Caregiver only)
              if (viewModel.isCaregiver && completionCount > 0) ...[
                const SizedBox(height: 14),
                _buildCompletionHistorySection(
                  context,
                  viewModel,
                  reminder,
                  isHistoryExpanded,
                ),
              ],

              // Mark as Done button (Elderly only)
              if (viewModel.isElderly && !isCompleted) ...[
                const SizedBox(height: 18), // Increased spacing
                SizedBox(
                  width: double.infinity,
                  height: 56, // Increased from 50
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _markAsDone(context, viewModel, reminderId),
                    icon: const Icon(Icons.check, size: 26), // Increased
                    label: const Text(
                      'Mark as Done',
                      style: TextStyle(
                        fontSize: 20, // Increased from 18
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],

              // Delete button (Caregiver only)
              if (viewModel.isCaregiver) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _confirmDelete(context, viewModel, reminderId, title),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red[700],
                      ),
                      label: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16, // Increased from 14
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Updated completion history section with larger fonts
  Widget _buildCompletionHistorySection(
    BuildContext context,
    ReminderListViewModel viewModel,
    Map<String, dynamic> reminder,
    bool isExpanded,
  ) {
    int completionCount = viewModel.getCompletionCount(reminder);
    double completionRate = viewModel.getCompletionRate(reminder);
    bool isRecurring = viewModel.isRecurringReminder(reminder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => viewModel.toggleHistoryExpansion(reminder['reminderId']),
          child: Container(
            padding: const EdgeInsets.all(14), // Increased
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.blue[700],
                  size: 22,
                ), // Increased
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion History',
                        style: TextStyle(
                          fontSize: 16, // Increased from 14
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Completed $completionCount ${completionCount == 1 ? 'time' : 'times'}',
                            style: TextStyle(
                              fontSize: 15, // Increased from 13
                              color: Colors.blue[800],
                            ),
                          ),
                          if (isRecurring) ...[
                            Text(
                              ' • ${(completionRate * 100).toStringAsFixed(0)}% rate',
                              style: TextStyle(
                                fontSize: 15, // Increased
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue[700],
                  size: 28, // Increased
                ),
              ],
            ),
          ),
        ),

        // Expanded history
        if (isExpanded) ...[
          const SizedBox(height: 14),
          _buildHistoryList(context, viewModel, reminder),
        ],
      ],
    );
  }

  // Updated history list with larger fonts
  Widget _buildHistoryList(
    BuildContext context,
    ReminderListViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    List<Map<String, dynamic>> history = viewModel.getCompletionHistory(
      reminder,
    );
    List<Map<String, dynamic>> recentHistory = history.reversed
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14), // Increased
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          ...recentHistory.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> completion = entry.value;
            Timestamp completedAt = completion['completedAt'];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < recentHistory.length - 1 ? 10 : 0, // Increased
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Colors.green[600],
                  ), // Increased
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      viewModel.formatCompletionDate(completedAt),
                      style: TextStyle(
                        fontSize: 16, // Increased from 14
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (history.length > 5) ...[
            const SizedBox(height: 10),
            Text(
              '+ ${history.length - 5} more',
              style: TextStyle(
                fontSize: 15, // Increased from 13
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Mark as Done (Elderly)
  Future<void> _markAsDone(
    BuildContext context,
    ReminderListViewModel viewModel,
    String reminderId,
  ) async {
    bool success = await viewModel.markReminderComplete(reminderId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Great job! Reminder completed! 🎉',
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
    } else if (viewModel.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Toggle reminder completion (checkbox)
  Future<void> _toggleCompletion(
    BuildContext context,
    ReminderListViewModel viewModel,
    Map<String, dynamic> reminder,
  ) async {
    String reminderId = reminder['reminderId'];
    bool currentStatus = reminder['isCompleted'] == true;
    bool isRecurring = viewModel.isRecurringReminder(reminder);

    // Prevent undo for recurring reminders
    if (currentStatus && isRecurring) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cannot undo recurring reminders. It will reset on the next cycle.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    bool success = await viewModel.toggleReminderCompletion(
      reminderId,
      currentStatus,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                currentStatus ? Icons.undo : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentStatus
                      ? 'Marked as incomplete'
                      : 'Great job! Reminder completed!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: currentStatus
              ? Colors.orange[700]
              : Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Confirm delete dialog (unchanged)
  Future<void> _confirmDelete(
    BuildContext context,
    ReminderListViewModel viewModel,
    String reminderId,
    String title,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Delete Reminder?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: const TextStyle(fontSize: 16),
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

    if (confirmed == true && context.mounted) {
      bool success = await viewModel.deleteReminder(reminderId);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reminder deleted',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Navigate to create reminder page (unchanged)
  void _navigateToCreateReminder(
    BuildContext context,
    ReminderListViewModel viewModel,
  ) {
    context.push('/caregiver/groups/${viewModel.groupId}/reminders/create');
  }

  // Navigate to edit reminder page (unchanged)
  void _navigateToEditReminder(
    BuildContext context,
    ReminderListViewModel viewModel,
    String reminderId,
  ) {
    context.push(
      '/caregiver/groups/${viewModel.groupId}/reminders/$reminderId/edit',
    );
  }
}
