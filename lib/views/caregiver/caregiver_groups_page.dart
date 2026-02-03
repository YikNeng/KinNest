import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/group_list_viewmodel.dart';

class CaregiverGroupsPage extends StatelessWidget {
  const CaregiverGroupsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupListViewModel()..initializeGroupsStream(),
      child: const _CaregiverGroupsPageBody(),
    );
  }
}

class _CaregiverGroupsPageBody extends StatelessWidget {
  const _CaregiverGroupsPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GroupListViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Groups',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGroup(context),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Create Group',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Build main body based on state
  Widget _buildBody(BuildContext context, GroupListViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading groups...',
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
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
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
                onPressed: () => viewModel.fetchGroups(),
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
    if (!viewModel.hasGroups) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No Groups Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first group to start\nmanaging care for your loved ones',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Groups list
    return RefreshIndicator(
      onRefresh: viewModel.refreshGroups,
      color: Colors.blue[700],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.groups.length,
        itemBuilder: (context, index) {
          final group = viewModel.groups[index];
          return _buildGroupCard(context, viewModel, group);
        },
      ),
    );
  }

  // Build individual group card
  Widget _buildGroupCard(
    BuildContext context,
    GroupListViewModel viewModel,
    Map<String, dynamic> group,
  ) {
    final String groupName = group['groupName'] ?? 'Unnamed Group';
    final int memberCount = viewModel.getMemberCount(group);
    final bool isAdmin = viewModel.isAdmin(group);
    final String roleLabel = viewModel.getRoleLabel(group);
    final Color roleColor = viewModel.getRoleColor(group);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToGroupDetail(context, group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name and role badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          roleLabel,
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
              ),
              const SizedBox(height: 16),

              // Member count
              Row(
                children: [
                  Icon(Icons.people_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // View details button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToGroupDetail(context, group),
                    icon: Icon(Icons.arrow_forward, color: Colors.blue[700]),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to create group page
  void _navigateToCreateGroup(BuildContext context) {
    context.push('/caregiver/groups/create');
  }

  // Navigate to group detail page
  void _navigateToGroupDetail(
    BuildContext context,
    Map<String, dynamic> group,
  ) {
    final String groupId = group['groupId'];
    context.push('/caregiver/groups/$groupId');
  }
}
