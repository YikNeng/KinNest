import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/group_detail_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupDetailViewModel(groupId: groupId),
      child: const _GroupDetailPageBody(),
    );
  }
}

class _GroupDetailPageBody extends StatelessWidget {
  const _GroupDetailPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GroupDetailViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // In the AppBar of GroupDetailPage
      appBar: AppBar(
        title: Text(
          viewModel.isLoading ? 'Loading...' : viewModel.groupName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
        // Add this actions parameter
        actions: [
          if (viewModel.isAdmin) // Only show for admin
            IconButton(
              icon: const Icon(Icons.settings, size: 28),
              onPressed: () => context.push(
                '/caregiver/groups/${viewModel.groupId}/settings',
              ),
              tooltip: 'Group Settings',
            ),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, GroupDetailViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading group details...',
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
                'Error Loading Group',
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

    // Not a member
    if (!viewModel.isMember) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: Colors.orange[700]),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are not a member of this group',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Go Back', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    // Group details
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group Info Card
            _buildGroupInfoCard(context, viewModel),
            const SizedBox(height: 16),

            // Members Section
            _buildMembersSection(context, viewModel),
            const SizedBox(height: 16),

            // Reminders Section
            _buildRemindersSection(context, viewModel),
            const SizedBox(height: 16),

            // Pending Invitations (Admin only)
            if (viewModel.isAdmin &&
                viewModel.pendingInvitations.isNotEmpty) ...[
              _buildInvitationsSection(context, viewModel),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // Group info card
  Widget _buildGroupInfoCard(
    BuildContext context,
    GroupDetailViewModel viewModel,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Group Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (viewModel.groupDescription != null) ...[
              const SizedBox(height: 16),
              Text(
                viewModel.groupDescription!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${viewModel.memberCount} ${viewModel.memberCount == 1 ? 'Member' : 'Members'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Members section
  Widget _buildMembersSection(
    BuildContext context,
    GroupDetailViewModel viewModel,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Invite button (admin only)
                if (viewModel.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToInvite(context, viewModel),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('Invite', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
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

            // Members list
            if (viewModel.members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No members yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.members.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 24, color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final member = viewModel.members[index];
                  return _buildMemberTile(viewModel, member);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Individual member tile
  Widget _buildMemberTile(
    GroupDetailViewModel viewModel,
    Map<String, dynamic> member,
  ) {
    String name = member['name'] ?? 'Unknown';
    String email = member['email'] ?? '';
    String role = viewModel.getMemberRole(member);
    Color roleColor = viewModel.getMemberRoleColor(member);
    bool isAdmin = member['isAdmin'] == true;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: roleColor.withOpacity(0.2),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 16,
                color: roleColor,
              ),
              const SizedBox(width: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reminders section
  Widget _buildRemindersSection(
    BuildContext context,
    GroupDetailViewModel viewModel,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Upcoming Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToReminders(context, viewModel),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reminders list
            if (viewModel.upcomingReminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming reminders',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.upcomingReminders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reminder = viewModel.upcomingReminders[index];
                  return _buildReminderTile(viewModel, reminder);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Individual reminder tile
  Widget _buildReminderTile(
    GroupDetailViewModel viewModel,
    Map<String, dynamic> reminder,
  ) {
    String title = reminder['title'] ?? 'Untitled';
    Timestamp scheduledTime = reminder['scheduledTime'];
    String timeString = viewModel.formatReminderTime(scheduledTime);
    bool isCompleted = viewModel.isReminderCompleted(reminder);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.schedule,
            color: isCompleted ? Colors.green[700] : Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pending invitations section (admin only)
  Widget _buildInvitationsSection(
    BuildContext context,
    GroupDetailViewModel viewModel,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.orange[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Pending Invitations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.pendingInvitations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invitation = viewModel.pendingInvitations[index];
                String email = invitation['email'] ?? '';
                String role = invitation['role'] ?? '';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Role: ${role.substring(0, 1).toUpperCase()}${role.substring(1)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to invite member page
  void _navigateToInvite(BuildContext context, GroupDetailViewModel viewModel) {
    context.push('/caregiver/groups/${viewModel.groupId}/invite');
  }

  // Navigate to reminders page
  void _navigateToReminders(
    BuildContext context,
    GroupDetailViewModel viewModel,
  ) {
    context.push('/caregiver/groups/${viewModel.groupId}/reminders');
  }
}
