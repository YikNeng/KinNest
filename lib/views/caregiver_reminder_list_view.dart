// lib/views/caregiver_reminder_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/caregiver_reminder_list_viewmodel.dart';
import '../models/reminder_model.dart';

class CaregiverReminderListView extends StatelessWidget {
  const CaregiverReminderListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverReminderListViewModel(),
      child: const CaregiverReminderListContent(),
    );
  }
}

class CaregiverReminderListContent extends StatelessWidget {
  const CaregiverReminderListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaregiverReminderListViewModel>();
    final filteredReminders = viewModel.getFilteredReminders();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.go('/caregiver/home'),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1F2937)),
            onPressed: () => viewModel.refreshReminders(),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Chips Row
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context,
                          viewModel,
                          'All',
                          viewModel.selectedFilter == 'All',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          viewModel,
                          'Today',
                          viewModel.selectedFilter == 'Today',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          viewModel,
                          'Upcoming',
                          viewModel.selectedFilter == 'Upcoming',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          viewModel,
                          'Recurring',
                          viewModel.selectedFilter == 'Recurring',
                        ),
                      ],
                    ),
                  ),
                ),

                // Reminders List
                Expanded(
                  child: filteredReminders.isEmpty
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          onRefresh: () async {
                            viewModel.refreshReminders();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredReminders.length,
                            itemBuilder: (context, index) {
                              final item = filteredReminders[index];
                              final reminder =
                                  item['reminder'] as ReminderModel;
                              final elderlyName = item['elderlyName'] as String;
                              return _buildReminderCard(
                                context,
                                reminder,
                                elderlyName,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create reminder page
          context.go('/caregiver/reminder/create');
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Reminder',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    CaregiverReminderListViewModel viewModel,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement filter logic in viewmodel
        viewModel.setFilter(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    ReminderModel reminder,
    String elderlyName,
  ) {
    Color typeColor;
    IconData typeIcon;

    switch (reminder.type) {
      case 'medicine':
        typeColor = const Color(0xFFEF4444);
        typeIcon = Icons.medication_outlined;
        break;
      case 'appointment':
        typeColor = const Color(0xFF3B82F6);
        typeIcon = Icons.calendar_today_outlined;
        break;
      case 'task':
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.task_outlined;
        break;
      default:
        typeColor = const Color(0xFF6B7280);
        typeIcon = Icons.notifications_outlined;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to reminder detail page with reminder ID
        context.go('/caregiver/reminder/detail', extra: reminder.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Elderly Name
                      Text(
                        elderlyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Reminder Title
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  reminder.getFormattedDateTime(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Badges Row
            Row(
              children: [
                // Recurring Badge
                if (reminder.isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.recurringPattern ?? 'Recurring',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (reminder.isRecurring) const SizedBox(width: 8),

                // Voice Note Indicator
                if (reminder.hasVoiceNote)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 14,
                          color: Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Voice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 64,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Reminders Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first reminder to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to create reminder page
                context.go('/caregiver/reminder/create');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Create Reminder',
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
          ],
        ),
      ),
    );
  }
}
