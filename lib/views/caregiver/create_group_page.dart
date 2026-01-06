import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/create_group_viewmodel.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGroupViewModel(),
      child: const _CreateGroupPageBody(),
    );
  }
}

class _CreateGroupPageBody extends StatelessWidget {
  const _CreateGroupPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CreateGroupViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Create New Group',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => _handleBackPress(context, viewModel),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Icon(Icons.group_add, size: 80, color: Colors.blue[700]),
              const SizedBox(height: 16),
              Text(
                'Create a Care Group',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Organize and manage care for your loved ones',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              const SizedBox(height: 40),

              // Group Name Field
              _buildLabel('Group Name *', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: viewModel.groupNameController,
                style: const TextStyle(fontSize: 18),
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: 'e.g., Tan Family Care',
                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  prefixIcon: Icon(
                    Icons.people,
                    size: 28,
                    color: Colors.blue[700],
                  ),
                  counterStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 24),

              // Description Field (Optional)
              _buildLabel('Description (Optional)', isRequired: false),
              const SizedBox(height: 8),
              TextField(
                controller: viewModel.descriptionController,
                style: const TextStyle(fontSize: 18),
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add a brief description about this care group...',
                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  counterStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 32),

              // Error Message
              if (viewModel.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Create Group Button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _handleCreateGroup(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _handleBackPress(context, viewModel),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be the admin of this group. You can invite elderly members after creation.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Build field label
  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
      ],
    );
  }

  // Handle create group button press
  Future<void> _handleCreateGroup(
    BuildContext context,
    CreateGroupViewModel viewModel,
  ) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Call create group method
    String? groupId = await viewModel.createGroup();

    if (groupId != null && context.mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Group created successfully!',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to group list
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        context.pop(); // Go back to groups list
      }
    }
    // If groupId is null, error message is already shown in UI
  }

  // Handle back button press
  void _handleBackPress(BuildContext context, CreateGroupViewModel viewModel) {
    // Check if form has content
    bool hasContent =
        viewModel.groupNameController.text.trim().isNotEmpty ||
        viewModel.descriptionController.text.trim().isNotEmpty;

    if (hasContent && !viewModel.isLoading) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Discard Changes?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to go back? Your changes will be lost.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                context.pop(); // Go back
              },
              child: Text(
                'Discard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // No content, go back directly
      context.pop();
    }
  }
}
