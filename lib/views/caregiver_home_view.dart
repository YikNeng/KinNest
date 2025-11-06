// lib/views/caregiver_home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/caregiver_home_viewmodel.dart';
import '../models/reminder_model.dart';

class CaregiverHomeView extends StatelessWidget {
  const CaregiverHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverHomeViewModel(),
      child: const CaregiverHomeContent(),
    );
  }
}

class CaregiverHomeContent extends StatelessWidget {
  const CaregiverHomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaregiverHomeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caregiver Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Good Morning!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),

              // Upcoming Reminders Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Upcoming Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Scroll List
              SizedBox(
                height: 150,
                child: viewModel.upcomingReminders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'No upcoming reminders',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: viewModel.upcomingReminders.length,
                        itemBuilder: (context, index) {
                          final item = viewModel.upcomingReminders[index];
                          final reminder = item['reminder'] as ReminderModel;
                          final elderlyName = item['elderlyName'] as String;
                          return _ReminderCard(
                            reminder: reminder,
                            elderlyName: elderlyName,
                            onTap: () {
                              // TODO: Navigate to reminder detail page with reminder ID
                              context.go('/caregiver/reminder/detail',
                                  extra: reminder.id);
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 32),

              // Quick Actions Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2x2 Grid Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _ActionButton(
                      icon: Icons.notifications_active,
                      label: 'Reminders',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        // TODO: Navigate to caregiver reminders page
                        context.go('/caregiver/reminder');
                      },
                    ),
                    _ActionButton(
                      icon: Icons.group,
                      label: 'Groups',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        // TODO: Navigate to caregiver groups page
                        context.go('/caregiver/groups');
                      },
                    ),
                    _ActionButton(
                      icon: Icons.add_alert,
                      label: 'Create Reminder',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        // TODO: Navigate to create reminder page
                        context.go('/caregiver/reminder/create');
                      },
                    ),
                    _ActionButton(
                      icon: Icons.person,
                      label: 'Profile',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        // TODO: Navigate to caregiver profile page
                        context.go('/caregiver/profile');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Statistics Card
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.group_work,
                            label: 'Groups',
                            value: viewModel.numberOfGroups.toString(),
                            color: const Color(0xFF4CAF50),
                          ),
                          _buildStatItem(
                            icon: Icons.elderly,
                            label: 'Elderly',
                            value: viewModel.numberOfElderly.toString(),
                            color: const Color(0xFF2196F3),
                          ),
                          _buildStatItem(
                            icon: Icons.today,
                            label: 'Today',
                            value: viewModel.numberOfRemindersToday.toString(),
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create reminder page
          context.go('/caregiver/reminder/create');
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Quick Create',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final String elderlyName;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.elderlyName,
    required this.onTap,
  });

  Color _getTypeColor() {
    switch (reminder.type) {
      case 'medicine':
        return const Color(0xFFEF4444);
      case 'appointment':
        return const Color(0xFF3B82F6);
      case 'task':
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
      case 'task':
        return Icons.task_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  reminder.getFormattedTime(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              elderlyName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C63FF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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
            const Spacer(),
            Text(
              reminder.getFormattedDate(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
