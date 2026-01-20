import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/caregiver_home_viewmodel.dart';

class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverHomeViewModel(),
      child: const _CaregiverHomePageBody(),
    );
  }
}

class _CaregiverHomePageBody extends StatelessWidget {
  const _CaregiverHomePageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CaregiverHomeViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // NO AppBar - greeting is now at the top
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, CaregiverHomeViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Main content
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Greeting Header as SliverAppBar (stays at top)
          SliverToBoxAdapter(child: _buildGreetingHeader(context, viewModel)),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Nearest Upcoming Reminder Section
                _buildNearestReminderSection(context, viewModel),

                const SizedBox(height: 32),

                const SizedBox(height: 20), // Extra space at bottom for nav bar
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Updated Greeting Header (now at top without AppBar)
  Widget _buildGreetingHeader(
    BuildContext context,
    CaregiverHomeViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        50,
        20,
        24,
      ), // Top padding for status bar
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[600]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Refresh button (top right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.getGreeting(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.caregiverName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh Icon Button
                IconButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.refresh(),
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Nearest Reminder Section
  Widget _buildNearestReminderSection(
    BuildContext context,
    CaregiverHomeViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(Icons.upcoming, size: 28, color: Colors.blue[700]),
            const SizedBox(width: 12),
            const Text(
              'Next Upcoming',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reminder Card or Empty State
        if (viewModel.hasUpcomingReminder)
          _buildNearestReminderCard(context, viewModel)
        else
          _buildNoUpcomingRemindersCard(context),
      ],
    );
  }

  // Nearest Reminder Card
  Widget _buildNearestReminderCard(
    BuildContext context,
    CaregiverHomeViewModel viewModel,
  ) {
    Color typeColor = viewModel.getReminderTypeColor();
    String typeIcon = viewModel.getReminderTypeIcon();
    String typeDisplayName = viewModel.getReminderTypeDisplayName();
    String repeatDisplayName = viewModel.getRepeatTypeDisplayName();
    bool isRecurring = viewModel.isRecurring;

    return InkWell(
      onTap: () => _navigateToReminderDetail(context, viewModel),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: typeColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: typeColor.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type icon + Time until
            Row(
              children: [
                // Type icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(typeIcon, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 16),

                // Time until
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.getTimeUntilReminder(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.formatScheduledTime(),
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              viewModel.reminderTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),

            // Description (if available)
            if (viewModel.reminderDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                viewModel.reminderDescription,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            // Assigned to
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(viewModel.assignedUserName),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned to',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          viewModel.assignedUserName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tags Row
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Type tag
                _buildTag(
                  label: typeDisplayName,
                  icon: Icons.label,
                  color: typeColor,
                ),

                // Recurring tag
                _buildTag(
                  label: repeatDisplayName,
                  icon: isRecurring ? Icons.repeat : Icons.event,
                  color: isRecurring ? Colors.purple : Colors.grey,
                ),

                // Group tag
                _buildTag(
                  label: viewModel.groupName,
                  icon: Icons.group,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // View Details Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToReminderDetail(context, viewModel),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No Upcoming Reminders Card
  Widget _buildNoUpcomingRemindersCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming reminders at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Tag Widget
  Widget _buildTag({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    MaterialColor materialColor = color is MaterialColor
        ? color
        : Colors.grey; // Fallback

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: materialColor[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: materialColor[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: materialColor[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: materialColor[900],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Get Initials
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Navigate to Nearest Upcoming Reminder Detail/Edit Page
  Future<void> _navigateToReminderDetail(
    BuildContext context,
    CaregiverHomeViewModel viewModel,
  ) async {
    // Get the nearest upcoming reminder
    Map<String, dynamic>? nearestReminder = viewModel.nearestReminder;

    if (nearestReminder != null) {
      String groupId = nearestReminder['groupId'];
      String reminderId = nearestReminder['reminderId'];

      // Navigate to edit page
      context.push('/caregiver/groups/$groupId/reminders/$reminderId/edit');
    } else {
      // No upcoming reminders, show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No upcoming reminders found'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
