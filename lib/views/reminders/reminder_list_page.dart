import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/reminder_viewmodel.dart';

class ReminderListPage extends StatelessWidget {
  const ReminderListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReminderViewModel(),
      child: const _ReminderListPageBody(),
    );
  }
}

class _ReminderListPageBody extends StatelessWidget {
  const _ReminderListPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ReminderViewModel>(context);

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
      // Floating Action Button - For BOTH caregivers and elderly
      floatingActionButton: viewModel.selectedGroup != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to create reminder page with selected group ID
                String groupId = viewModel.selectedGroup!['groupId'];

                // Different routes for caregiver vs elderly
                if (viewModel.isCaregiver) {
                  context.push('/caregiver/groups/$groupId/reminders/create');
                } else if (viewModel.isElderly) {
                  context.push('/elderly/groups/$groupId/reminders/create');
                }
              },
              backgroundColor: Colors.blue[700],
              icon: const Icon(Icons.add, size: 28),
              label: const Text(
                'New Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, ReminderViewModel viewModel) {
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
      return _buildNoGroupsState(viewModel);
    }

    // Content
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: Column(
        children: [
          // Group Selector (show for both roles if they have multiple groups)
          if (viewModel.groups.length > 1)
            _buildGroupSelector(context, viewModel),

          // Filter Buttons
          _buildFilterButtons(context, viewModel),

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

  Widget _buildNoGroupsState(ReminderViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              viewModel.isCaregiver ? 'No Groups Yet' : 'Not in Any Group',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.isCaregiver
                  ? 'Create a care group to start managing reminders'
                  : 'Ask your caregiver to invite you to a group',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Group Selector Dropdown
  Widget _buildGroupSelector(
    BuildContext context,
    ReminderViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

  // Filter Buttons (Upcoming / Past)
  Widget _buildFilterButtons(
    BuildContext context,
    ReminderViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Upcoming Button
          Expanded(
            child: _buildFilterButton(
              context,
              viewModel,
              'upcoming',
              'Upcoming',
              viewModel.upcomingCount,
              Icons.schedule,
            ),
          ),
          // Past Button
          Expanded(
            child: _buildFilterButton(
              context,
              viewModel,
              'past',
              'Past',
              viewModel.pastCount,
              Icons.history,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    ReminderViewModel viewModel,
    String mode,
    String label,
    int count,
    IconData icon,
  ) {
    bool isSelected = viewModel.filterMode == mode;

    return GestureDetector(
      onTap: () => viewModel.setFilterMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ReminderViewModel viewModel) {
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
  Widget _buildReminderList(BuildContext context, ReminderViewModel viewModel) {
    if (viewModel.reminders.isEmpty) {
      return _buildEmptyState(viewModel);
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

  Widget _buildEmptyState(ReminderViewModel viewModel) {
    String message = viewModel.filterMode == 'upcoming'
        ? 'No upcoming reminders'
        : 'No past reminders';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              viewModel.filterMode == 'upcoming'
                  ? 'No Upcoming Reminders'
                  : 'No Past Reminders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
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
    ReminderViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    String reminderType = reminder['type'] ?? 'normal';
    IconData icon = viewModel.getReminderIcon(reminderType);
    Color color = viewModel.getReminderColor(reminderType);

    String? assignedTo = reminder['assignedTo'];
    String elderlyName = assignedTo != null
        ? viewModel.getElderlyName(assignedTo)
        : 'Unassigned';

    Timestamp scheduledTime = reminder['scheduledTime'];
    String scheduledTimeStr = viewModel.formatScheduledTime(scheduledTime);

    // Get status for past reminders
    bool isPast = viewModel.filterMode == 'past';
    String statusTag = isPast ? viewModel.getStatusTag(reminder) : '';
    Color statusColor = isPast
        ? viewModel.getStatusColor(reminder)
        : Colors.grey;

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
            String reminderId = reminder['reminderId'];
            String groupId = reminder['groupId'];

            // Different navigation for caregiver vs elderly
            if (viewModel.isCaregiver) {
              // Caregiver can edit
              context.push(
                '/caregiver/groups/$groupId/reminders/$reminderId/edit',
              );
            } else {
              // Elderly can edit their own reminders too
              context.push(
                '/elderly/groups/$groupId/reminders/$reminderId/edit',
              );
            }
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

                      // Show elderly name only for caregiver
                      if (viewModel.isCaregiver) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.grey[600],
                            ),
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
                      ],

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

                      const SizedBox(height: 8),

                      // Tags Row (Type + Status for past)
                      Row(
                        children: [
                          // Reminder Type Badge
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

                          // Status Badge (for past reminders)
                          if (isPast && statusTag.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusTag == 'Completed'
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusTag,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Icon/Button
                // Elderly: Complete button for upcoming incomplete reminders
                // Caregiver: Chevron to edit (cannot complete)
                if (viewModel.isElderly &&
                    viewModel.filterMode == 'upcoming' &&
                    !viewModel.isCompleted(reminder))
                  IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green[600],
                      size: 32,
                    ),
                    onPressed: () async {
                      bool success = await viewModel.markReminderComplete(
                        reminder['reminderId'],
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder marked as complete!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
