// lib/views/caregiver_home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/caregiver_home_viewmodel.dart';
import '../models/reminder_model.dart';
import 'package:intl/intl.dart';

class CaregiverHomeView extends StatelessWidget {
  const CaregiverHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverHomeViewModel(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Caregiver Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF6C63FF),
          elevation: 0,
        ),
        body: Consumer<CaregiverHomeViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Reminders Section
                  _buildUpcomingRemindersSection(context, viewModel),
                  SizedBox(height: 20),

                  // Main Action Grid
                  _buildActionGrid(context),
                  SizedBox(height: 20),

                  // Quick Statistics Card
                  _buildStatisticsCard(context, viewModel),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // TODO: Navigate to create reminder page
            context.go('/caregiver/reminder/create');
          },
          backgroundColor: Color(0xFF6C63FF),
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Quick Create',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingRemindersSection(
      BuildContext context, CaregiverHomeViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Upcoming Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 140,
            child: viewModel.upcomingReminders.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming reminders',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemCount: viewModel.upcomingReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = viewModel.upcomingReminders[index];
                      return _buildReminderCard(context, reminder);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, ReminderModel reminder) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM dd');

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to reminder detail page with reminder ID
        context.go('/caregiver/reminder/detail', extra: reminder.id);
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 12, left: 4, top: 4, bottom: 4),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.elderlyName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  timeFormat.format(reminder.dateTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  dateFormat.format(reminder.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildActionCard(
            context: context,
            title: 'Reminders',
            icon: Icons.notifications_active,
            color: Color(0xFF6C63FF),
            onTap: () {
              // TODO: Navigate to caregiver reminders page
              context.go('/caregiver/reminder');
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Groups',
            icon: Icons.group,
            color: Color(0xFF4CAF50),
            onTap: () {
              // TODO: Navigate to caregiver groups page
              context.go('/caregiver/groups');
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Create Reminder',
            icon: Icons.add_alert,
            color: Color(0xFFFF9800),
            onTap: () {
              // TODO: Navigate to create reminder page
              context.go('/caregiver/reminder/create');
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            color: Color(0xFF2196F3),
            onTap: () {
              // TODO: Navigate to caregiver profile page
              context.go('/caregiver/profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
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
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
      BuildContext context, CaregiverHomeViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.group_work,
                  label: 'Groups',
                  value: viewModel.numberOfGroups.toString(),
                  color: Color(0xFF4CAF50),
                ),
                _buildStatItem(
                  icon: Icons.elderly,
                  label: 'Elderly',
                  value: viewModel.numberOfElderly.toString(),
                  color: Color(0xFF2196F3),
                ),
                _buildStatItem(
                  icon: Icons.today,
                  label: 'Today',
                  value: viewModel.numberOfRemindersToday.toString(),
                  color: Color(0xFFFF9800),
                ),
              ],
            ),
          ],
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
          padding: EdgeInsets.all(12),
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
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
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
