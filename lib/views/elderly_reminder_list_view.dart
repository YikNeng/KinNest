import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/elderly_reminder_list_viewmodel.dart';
import '../models/reminder_model.dart';

class ElderlyReminderListView extends StatelessWidget {
  const ElderlyReminderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ElderlyReminderListViewModel(),
      child: const ElderlyReminderListContent(),
    );
  }
}

class ElderlyReminderListContent extends StatelessWidget {
  const ElderlyReminderListContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ElderlyReminderListViewModel>();
    final upcomingReminders = viewModel.getUpcomingReminders();
    final pastReminders = viewModel.getPastReminders();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.go('/elderly/home'),
        ),
        title: const Text(
          'My Reminders',
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
          : viewModel.allReminders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    viewModel.refreshReminders();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Upcoming Reminders Section
                      if (upcomingReminders.isNotEmpty) ...[
                        const Text(
                          'Upcoming Reminders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...upcomingReminders.map((reminder) => _ReminderCard(
                              reminder: reminder,
                              isPast: false,
                              onTap: () =>
                                  context.push('/elderly/reminder/detail'),
                            )),
                        const SizedBox(height: 24),
                      ],

                      // Past Reminders Section
                      if (pastReminders.isNotEmpty) ...[
                        const Text(
                          'Past Reminders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pastReminders.map((reminder) => _ReminderCard(
                              reminder: reminder,
                              isPast: true,
                              onTap: () =>
                                  context.push('/elderly/reminder/detail'),
                            )),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/elderly/reminder/create'),
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reminders Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a reminder',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isPast;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.isPast,
    required this.onTap,
  });

  Color _getTypeColor() {
    switch (reminder.type) {
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

  IconData _getTypeIcon() {
    switch (reminder.type) {
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

  String _getTypeLabel() {
    switch (reminder.type) {
      case 'medicine':
        return 'Medicine';
      case 'appointment':
        return 'Appointment';
      case 'exercise':
        return 'Exercise';
      default:
        return 'Reminder';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPast
              ? Border.all(color: const Color(0xFFE5E7EB), width: 1)
              : null,
          boxShadow: isPast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPast
                    ? const Color(0xFFF3F4F6)
                    : _getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(),
                color: isPast ? const Color(0xFF9CA3AF) : _getTypeColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color:
                            isPast ? const Color(0xFFD1D5DB) : _getTypeColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reminder.getFormattedDate()} • ${reminder.getFormattedTime()}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isPast
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? const Color(0xFFF3F4F6)
                              : _getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isPast
                                ? const Color(0xFF9CA3AF)
                                : _getTypeColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? const Color(0xFFF3F4F6)
                              : reminder.isRecurring
                                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                                  : const Color(0xFF6B7280).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              reminder.isRecurring
                                  ? Icons.repeat
                                  : Icons.event_outlined,
                              size: 13,
                              color: isPast
                                  ? const Color(0xFF9CA3AF)
                                  : reminder.isRecurring
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              reminder.getRecurringText(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isPast
                                    ? const Color(0xFF9CA3AF)
                                    : reminder.isRecurring
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFF6B7280),
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

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPast ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
