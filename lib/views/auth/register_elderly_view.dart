// lib/views/auth/register_elderly_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth/register_elderly_viewmodel.dart';

class RegisterElderlyView extends StatelessWidget {
  const RegisterElderlyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterElderlyViewModel(),
      child: const RegisterElderlyContent(),
    );
  }
}

class RegisterElderlyContent extends StatelessWidget {
  const RegisterElderlyContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterElderlyViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: 28),
          onPressed: () => context.go('/register'),
        ),
        title: const Text(
          'Elderly Registration',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Personal Information Section
              Container(
                padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Username',
                      controller: viewModel.usernameController,
                      icon: Icons.person_outline,
                      errorText: viewModel.usernameError,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email',
                      controller: viewModel.emailController,
                      icon: Icons.email_outlined,
                      errorText: viewModel.emailError,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Password',
                      controller: viewModel.passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      errorText: viewModel.passwordError,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Confirm Password',
                      controller: viewModel.confirmPasswordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      errorText: viewModel.confirmPasswordError,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Health Information Section
              Container(
                padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Health Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Age',
                      controller: viewModel.ageController,
                      icon: Icons.cake_outlined,
                      errorText: viewModel.ageError,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Height (cm)',
                      controller: viewModel.heightController,
                      icon: Icons.height,
                      errorText: viewModel.heightError,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Weight (kg)',
                      controller: viewModel.weightController,
                      icon: Icons.monitor_weight_outlined,
                      errorText: viewModel.weightError,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Chronic Disease Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Chronic Disease',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Switch(
                            value: viewModel.hasChronicDisease,
                            onChanged: (value) =>
                                viewModel.setChronicDisease(value),
                            activeColor: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),

                    if (viewModel.hasChronicDisease) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Chronic Disease Notes',
                        controller: viewModel.chronicDiseaseNotesController,
                        icon: Icons.notes,
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Group Creation/Join Section
              Container(
                padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Group (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => viewModel.setGroupOption('join'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: viewModel.groupOption == 'join'
                                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: viewModel.groupOption == 'join'
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE5E7EB),
                                  width:
                                      viewModel.groupOption == 'join' ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                'Join Group',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: viewModel.groupOption == 'join'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: viewModel.groupOption == 'join'
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => viewModel.setGroupOption('create'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: viewModel.groupOption == 'create'
                                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: viewModel.groupOption == 'create'
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE5E7EB),
                                  width:
                                      viewModel.groupOption == 'create' ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                'Create Group',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: viewModel.groupOption == 'create'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: viewModel.groupOption == 'create'
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.groupOption == 'join')
                      _buildTextField(
                        label: 'Invite Code',
                        controller: viewModel.inviteCodeController,
                        icon: Icons.qr_code,
                      )
                    else
                      _buildTextField(
                        label: 'Group Name',
                        controller: viewModel.groupNameController,
                        icon: Icons.group,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _handleRegister(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    String? errorText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister(
    BuildContext context,
    RegisterElderlyViewModel viewModel,
  ) async {
    final success = await viewModel.register();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registered'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go('/elderly/home');
    }
  }
}
