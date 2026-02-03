import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Reminders',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: viewModel.selectedGroup != null
          ? SizedBox(
              height: 65,
              width: 220,
              child: FloatingActionButton.extended(
                onPressed: () {
                  String groupId = viewModel.selectedGroup!['groupId'];
                  if (viewModel.isCaregiver) {
                    context.push('/caregiver/groups/$groupId/reminders/create');
                  } else if (viewModel.isElderly) {
                    context.push('/elderly/groups/$groupId/reminders/create');
                  }
                },
                backgroundColor: Colors.blue[800],
                icon: const Icon(Icons.add, size: 30, color: Colors.white),
                label: const Text(
                  'Create Reminder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, ReminderViewModel viewModel) {
    if (viewModel.isLoading && viewModel.groups.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Colors.blue[800]));
    }

    if (viewModel.groups.isEmpty) {
      return _buildNoGroupsState(viewModel);
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: Column(
        children: [
          // Group Selector
          if (viewModel.groups.length > 1)
            _buildGroupSelector(context, viewModel),

          // Filter Buttons
          _buildFilterButtons(context, viewModel),

          // Error Message
          if (viewModel.errorMessage != null) _buildErrorMessage(viewModel),

          // Main Content Area
          Expanded(
            child: viewModel.filterMode == 'past'
                ? _buildPastHistoryList(
                    context,
                    viewModel,
                    viewModel.selectedGroup!['groupId'],
                  )
                : (viewModel.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue[800],
                          ),
                        )
                      : _buildReminderList(context, viewModel)),
          ),
        ],
      ),
    );
  }

  // History List Widget
  Widget _buildPastHistoryList(
    BuildContext context,
    ReminderViewModel viewModel,
    String currentGroupId,
  ) {
    // Get Active Overdue Reminders from ViewModel

    List<Map<String, dynamic>> activeOverdueReminders = viewModel.reminders;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reminder_history')
          .where('status', whereIn: ['completed', 'overdue'])
          .where('groupId', isEqualTo: currentGroupId)
          .orderBy('scheduledFor', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blue[800]),
          );
        }

        // Prepare Lists
        List<Map<String, dynamic>> historyList = [];

        // Parse Firestore History Data
        if (snapshot.hasData) {
          historyList = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();
        }

        // Convert Active Overdue to Display Format (Match History Structure)
        List<Map<String, dynamic>> overdueList = activeOverdueReminders.map((
          r,
        ) {
          return {
            'taskTitle': r['title'],
            'status': 'overdue',
            'scheduledFor': r['scheduledTime'],
            'completedAt': null,
            'originalReminderId': r['reminderId'],
            'groupId': r['groupId'],
          };
        }).toList();

        // Merge Active Overdue + History
        List<Map<String, dynamic>> combinedList = [
          ...overdueList,
          ...historyList,
        ];

        // Sort Combined List
        combinedList.sort((a, b) {
          Timestamp tA = a['scheduledFor'];
          Timestamp tB = b['scheduledFor'];
          return tB.compareTo(tA);
        });

        // Handle Empty State
        if (combinedList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No past history found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
          );
        }

        // Build List
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combinedList.length,
          itemBuilder: (context, index) {
            return _buildHistoryTile(combinedList[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> data) {
    // Safely parse data
    String title = data['taskTitle'] ?? 'Unknown Task';
    String status = data['status'] ?? 'completed';

    // Timestamp handling
    DateTime scheduledFor = (data['scheduledFor'] as Timestamp).toDate();
    DateTime? completedAt = data['completedAt'] != null
        ? (data['completedAt'] as Timestamp).toDate()
        : null;

    // Define Colors based on status
    Color statusColor;
    IconData statusIcon;
    Color bgColor;

    if (status == 'overdue') {
      statusColor = Colors.red.shade800;
      bgColor = Colors.red.shade50;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.green.shade800;
      bgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle_outline;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Scheduled: ${DateFormat('MMM dd, hh:mm a').format(scheduledFor)}",
            ),
            if (completedAt != null)
              Text(
                "Completed: ${DateFormat('MMM dd, hh:mm a').format(completedAt)}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoGroupsState(ReminderViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            viewModel.isCaregiver ? 'No Groups Yet' : 'Not in Any Group',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(
    BuildContext context,
    ReminderViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue[800],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: viewModel.selectedGroup,
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down_circle,
              color: Colors.blue[800],
              size: 30,
            ),
            items: viewModel.groups.map((group) {
              return DropdownMenuItem(
                value: group,
                child: Text(
                  group['groupName'] ?? 'Unnamed Group',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) viewModel.selectGroup(val);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons(
    BuildContext context,
    ReminderViewModel viewModel,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              viewModel,
              'upcoming',
              'UPCOMING',
              viewModel.upcomingCount,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTabButton(
              viewModel,
              'past',
              'PAST',
              viewModel.pastCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    ReminderViewModel vm,
    String mode,
    String label,
    int count,
  ) {
    bool isSelected = vm.filterMode == mode;
    return InkWell(
      onTap: () => vm.setFilterMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blue[800]!, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue[900] : Colors.grey[700],
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[800] : Colors.grey[500],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700], size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[900]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: viewModel.clearError,
            color: Colors.red[900],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(BuildContext context, ReminderViewModel viewModel) {
    if (viewModel.reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No upcoming reminders',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: viewModel.reminders.length,
      itemBuilder: (context, index) {
        return _buildReminderCard(
          context,
          viewModel,
          viewModel.reminders[index],
        );
      },
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    ReminderViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    // Basic Properties
    String type = reminder['type'] ?? 'General';
    Color color = viewModel.getReminderColor(type);

    // Assigned User Info
    String assignedToId = reminder['assignedTo'] ?? '';
    String assignedName = viewModel.getElderlyName(assignedToId);

    // Time
    Timestamp scheduledTs = reminder['scheduledTime'];
    String timeString = viewModel.formatScheduledTime(scheduledTs);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            String id = reminder['reminderId'];
            String grp = reminder['groupId'];
            String route = viewModel.isCaregiver ? '/caregiver' : '/elderly';
            context.push('$route/groups/$grp/reminders/$id/edit');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      viewModel.getReminderIcon(type),
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      reminder['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    if (reminder['description'] != null &&
                        reminder['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          reminder['description'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Info Grid (Time & Person)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          // Time Row
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 24,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          // Assigned Person Row
                          if (viewModel.isCaregiver)
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'For:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    assignedName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          // Recursive Info Row
                          if (viewModel.isCaregiver)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                          _buildRecursiveDetails(reminder),
                        ],
                      ),
                    ),

                    // Medication Specifics
                    if (type.toLowerCase() == 'medication' &&
                        reminder['typeSpecificData'] != null)
                      _buildMedicationDetails(reminder['typeSpecificData']),

                    // Action Button
                    if (viewModel.isElderly &&
                        viewModel.filterMode == 'upcoming' &&
                        !viewModel.isCompleted(reminder)) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            bool success = await viewModel.markReminderComplete(
                              reminder['reminderId'],
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Great Job! Reminder completed.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle, size: 28),
                          label: const Text(
                            'MARK AS DONE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecursiveDetails(Map<String, dynamic> reminder) {
    String repeatType = reminder['repeatType'] ?? 'once';

    if (repeatType == 'once') {
      return Row(
        children: [
          Icon(Icons.repeat_one, size: 24, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            'One-time Task',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (repeatType == 'specific_days') {
      List<dynamic> days = reminder['repeatDays'] ?? [];
      if (days.length == 7) {
        return _buildRecurringRow(Icons.all_inclusive, 'Every Day');
      }
      List<String> weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 24, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(7, (index) {
                int dayVal = index + 1;
                bool isSelected = days.contains(dayVal);
                return Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[600] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    weekLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[500],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    String label = '';
    switch (repeatType) {
      case 'daily':
        label = 'Every Day';
        break;
      case 'weekly':
        label = 'Weekly';
        break;
      case 'monthly':
        label = 'Monthly';
        break;
      default:
        label = 'Recurring';
    }
    return _buildRecurringRow(Icons.repeat, label);
  }

  Widget _buildRecurringRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationDetails(Map<String, dynamic> data) {
    if (data['medications'] != null && data['medications'] is List) {
      List<dynamic> meds = data['medications'];
      if (meds.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, size: 28, color: Colors.orange[800]),
                const SizedBox(width: 12),
                Text(
                  'Medication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...meds.map((med) {
              if (med is! Map) return const SizedBox.shrink();
              Map<String, dynamic> m = med as Map<String, dynamic>;
              String name = m['name'] ?? 'Unknown Medicine';
              String dosage = m['dosage'] ?? '';
              String timing = m['mealTiming'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          if (dosage.isNotEmpty)
                            Text(
                              dosage,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          if (timing.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 16,
                                    color: Colors.orange[800],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timing,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
