import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/caregiver_profile_viewmodel.dart';

class CaregiverProfilePage extends StatelessWidget {
  const CaregiverProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaregiverProfileViewModel(),
      child: const _CaregiverProfilePageBody(),
    );
  }
}

class _CaregiverProfilePageBody extends StatelessWidget {
  const _CaregiverProfilePageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CaregiverProfileViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false, // No back button on profile page
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, CaregiverProfileViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Error state
    if (viewModel.errorMessage != null && viewModel.userData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Profile',
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

    // Profile content
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: Colors.blue[700],
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            _buildProfileHeader(context, viewModel),

            const SizedBox(height: 24),

            // Success/Error Messages
            if (viewModel.successMessage != null)
              _buildSuccessMessage(viewModel),
            if (viewModel.errorMessage != null) _buildErrorMessage(viewModel),

            // Personal Info Section
            _buildPersonalInfoSection(context, viewModel),

            const SizedBox(height: 24),

            // Groups Section
            _buildGroupsSection(context, viewModel),

            const SizedBox(height: 24),

            // Actions Section
            _buildActionsSection(context, viewModel),

            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context, viewModel),
          ],
        ),
      ),
    );
  }

  // Profile Header
  Widget _buildProfileHeader(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(viewModel.userName),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            viewModel.userName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            viewModel.userEmail,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Caregiver',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Success Message
  Widget _buildSuccessMessage(CaregiverProfileViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.successMessage!,
              style: TextStyle(fontSize: 15, color: Colors.green[900]),
            ),
          ),
          IconButton(
            onPressed: viewModel.clearMessages,
            icon: Icon(Icons.close, color: Colors.green[700]),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // Error Message
  Widget _buildErrorMessage(CaregiverProfileViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(fontSize: 15, color: Colors.red[900]),
            ),
          ),
          IconButton(
            onPressed: viewModel.clearMessages,
            icon: Icon(Icons.close, color: Colors.red[700]),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // Personal Info Section
  Widget _buildPersonalInfoSection(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: viewModel.userName,
            onTap: () => _showEditNameDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  // Groups Section
  Widget _buildGroupsSection(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) {
    return _buildSection(
      title: 'My Groups',
      icon: Icons.group,
      child: Column(
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Total Groups',
                  value: viewModel.groupCount.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'As Admin',
                  value: viewModel.adminGroupCount.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),

          if (viewModel.userGroups.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'You are not a member of any groups yet',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...viewModel.userGroups.map((group) {
              return _buildGroupCard(context, viewModel, group);
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Group Card
  Widget _buildGroupCard(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
    Map<String, dynamic> group,
  ) {
    String groupName = group['groupName'];
    String role = group['role'];
    int memberCount = group['memberCount'];
    Color roleColor = viewModel.getRoleBadgeColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.group, color: roleColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions Section
  Widget _buildActionsSection(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) {
    return _buildSection(
      title: 'Account Actions',
      icon: Icons.settings,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => _showChangePasswordDialog(context, viewModel),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // Logout Button
  Widget _buildLogoutButton(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context, viewModel),
        icon: const Icon(Icons.logout, size: 24),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Section Builder
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // Info Row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, size: 20, color: Colors.blue[700]),
          ],
        ),
      ),
    );
  }

  // Stat Card
  Widget _buildStatCard({
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action Button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: color[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: color[900],
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: color[600]),
          ],
        ),
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

  // Edit Name Dialog
  Future<void> _showEditNameDialog(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) async {
    TextEditingController nameController = TextEditingController(
      text: viewModel.userName,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(fontSize: 16),
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              Navigator.of(dialogContext).pop();

              if (context.mounted) {
                bool success = await viewModel.updateProfileName(newName);
                if (success) {
                  // Success message shown in ViewModel
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Edit Email Dialog
  Future<void> _showEditEmailDialog(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) async {
    TextEditingController emailController = TextEditingController(
      text: viewModel.userEmail,
    );
    TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Change Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your new email and current password to verify.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  style: const TextStyle(fontSize: 17),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New Email',
                    labelStyle: const TextStyle(fontSize: 16),
                    hintText: 'Enter new email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(fontSize: 17),
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(fontSize: 16),
                    hintText: 'Enter current password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newEmail = emailController.text.trim();
                  String password = passwordController.text;
                  Navigator.of(dialogContext).pop();

                  if (context.mounted) {
                    bool success = await viewModel.updateEmail(
                      newEmail: newEmail,
                      currentPassword: password,
                    );
                    if (success) {
                      // Success message shown in ViewModel
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Change Password Dialog
  Future<void> _showChangePasswordDialog(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) async {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextField(
                    controller: currentPasswordController,
                    style: const TextStyle(fontSize: 17),
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(fontSize: 16),
                      hintText: 'Enter current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextField(
                    controller: newPasswordController,
                    style: const TextStyle(fontSize: 17),
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(fontSize: 16),
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: confirmPasswordController,
                    style: const TextStyle(fontSize: 17),
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: const TextStyle(fontSize: 16),
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password Requirements
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password must:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirement('Be at least 6 characters'),
                        _buildRequirement('Be different from current password'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String currentPassword = currentPasswordController.text;
                  String newPassword = newPasswordController.text;
                  String confirmPassword = confirmPasswordController.text;
                  Navigator.of(dialogContext).pop();

                  if (context.mounted) {
                    bool success = await viewModel.changePassword(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                      confirmPassword: confirmPassword,
                    );
                    if (success) {
                      // Success message shown in ViewModel
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  // Confirm Logout
  Future<void> _confirmLogout(
    BuildContext context,
    CaregiverProfileViewModel viewModel,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Log Out?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 16),
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
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bool success = await viewModel.signOut();
      if (success && context.mounted) {
        // Navigate to login page
        context.go('/login');
      }
    }
  }
}
