import 'package:flutter/material.dart';
import 'package:latest_fyp/viewmodels/manage_group_members_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../models/group_member_model.dart';

class ManageGroupMembersPage extends StatelessWidget {
  final String groupId;

  const ManageGroupMembersPage({Key? key, required this.groupId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageGroupMembersViewModel(groupId: groupId),
      child: const _ManageGroupMembersPageBody(),
    );
  }
}

class _ManageGroupMembersPageBody extends StatelessWidget {
  const _ManageGroupMembersPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ManageGroupMembersViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manage Members',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ManageGroupMembersViewModel viewModel,
  ) {
    // Access denied
    if (!viewModel.isAdmin && !viewModel.isLoading) {
      return _buildAccessDenied();
    }

    // Loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading members...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Content
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: Column(
        children: [
          // Error Message
          if (viewModel.errorMessage != null) _buildErrorMessage(viewModel),

          // Member Count Header
          _buildMemberCountHeader(viewModel),

          // Member List
          Expanded(
            child: viewModel.hasNonAdminMembers
                ? _buildMemberList(context, viewModel)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  // Access Denied Widget
  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 100, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Only group admins can manage members',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Error Message
  Widget _buildErrorMessage(ManageGroupMembersViewModel viewModel) {
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

  // Member Count Header
  Widget _buildMemberCountHeader(ManageGroupMembersViewModel viewModel) {
    int totalMembers = viewModel.members.length;
    int nonAdminCount = viewModel.nonAdminMembers.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.blue[700], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Members',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalMembers member${totalMembers != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                if (nonAdminCount > 0)
                  Text(
                    '$nonAdminCount non-admin member${nonAdminCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Other Members',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This group only has you as a member.\nInvite elderly members to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Member List
  Widget _buildMemberList(
    BuildContext context,
    ManageGroupMembersViewModel viewModel,
  ) {
    // Show only non-admin members in the list
    List<GroupMemberModel> membersToShow = viewModel.nonAdminMembers;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: membersToShow.length,
      itemBuilder: (context, index) {
        GroupMemberModel member = membersToShow[index];
        return _buildMemberCard(context, viewModel, member);
      },
    );
  }

  // Member Card
  Widget _buildMemberCard(
    BuildContext context,
    ManageGroupMembersViewModel viewModel,
    GroupMemberModel member,
  ) {
    bool isCurrentUser = member.uid == viewModel.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: member.roleColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(member.roleIcon, color: member.roleColor, size: 32),
            ),

            const SizedBox(width: 16),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Email
                  if (member.email.isNotEmpty)
                    Text(
                      member.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: member.roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: member.roleColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      member.roleLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: member.roleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Remove Button
            if (!isCurrentUser && !member.isAdmin)
              IconButton(
                onPressed: () =>
                    _confirmRemoveMember(context, viewModel, member),
                icon: const Icon(Icons.delete, size: 28),
                color: Colors.red[600],
                tooltip: 'Remove member',
              ),
          ],
        ),
      ),
    );
  }

  // Confirm Remove Member Dialog
  Future<void> _confirmRemoveMember(
    BuildContext context,
    ManageGroupMembersViewModel viewModel,
    GroupMemberModel member,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Remove Member',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${member.name} from this group?\n\n'
          'They will lose access to all group reminders and activities.',
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
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      bool success = await viewModel.removeMember(member.uid);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} removed from group'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted && viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
