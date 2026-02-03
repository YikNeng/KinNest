import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/register_viewmodel.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: const _RegisterViewBody(),
    );
  }
}

class _RegisterViewBody extends StatelessWidget {
  const _RegisterViewBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RegisterViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[700], size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Role Selection Section
              _buildSectionTitle('Select Your Role'),
              const SizedBox(height: 16),
              _buildRoleSelection(context, viewModel),

              const SizedBox(height: 32),

              // Common Fields Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),

              // Name Field
              _buildLabel('Full Name *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: viewModel.nameController,
                hintText: 'Enter your full name',
                icon: Icons.person_outline,
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 20),

              // Email Field
              _buildLabel('Email *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: viewModel.emailController,
                hintText: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 20),

              // Password Field
              _buildLabel('Password *'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: viewModel.passwordController,
                hintText: 'Enter password (min 6 characters)',
                obscureText: viewModel.obscurePassword,
                onToggle: viewModel.togglePasswordVisibility,
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              _buildLabel('Confirm Password *'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: viewModel.confirmPasswordController,
                hintText: 'Re-enter password',
                obscureText: viewModel.obscureConfirmPassword,
                onToggle: viewModel.toggleConfirmPasswordVisibility,
                onChanged: (_) => viewModel.clearError(),
              ),

              const SizedBox(height: 20),

              // Phone Field
              _buildLabel('Phone Number (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: viewModel.phoneController,
                hintText: '+60123456789',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              // Elderly-specific fields
              if (viewModel.isElderlySelected) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Health Information'),
                const SizedBox(height: 16),
                _buildElderlyFields(viewModel),
              ],

              const SizedBox(height: 24),

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

              // Register Button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _handleRegister(context, viewModel),
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Role selection buttons
  Widget _buildRoleSelection(
    BuildContext context,
    RegisterViewModel viewModel,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            context: context,
            role: 'elderly',
            title: 'Elderly',
            icon: Icons.elderly,
            isSelected: viewModel.selectedRole == 'elderly',
            onTap: () => viewModel.setRole('elderly'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRoleCard(
            context: context,
            role: 'caregiver',
            title: 'Caregiver',
            icon: Icons.favorite_border,
            isSelected: viewModel.selectedRole == 'caregiver',
            onTap: () => viewModel.setRole('caregiver'),
          ),
        ),
      ],
    );
  }

  // Individual role card
  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Elderly-specific fields
  Widget _buildElderlyFields(RegisterViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Age
        _buildLabel('Age *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: viewModel.ageController,
          hintText: 'Enter your age',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => viewModel.clearError(),
        ),

        const SizedBox(height: 20),

        // Height
        _buildLabel('Height (cm) *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: viewModel.heightController,
          hintText: 'Enter your height in cm',
          icon: Icons.height_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => viewModel.clearError(),
        ),

        const SizedBox(height: 20),

        // Weight
        _buildLabel('Weight (kg) *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: viewModel.weightController,
          hintText: 'Enter your weight in kg',
          icon: Icons.monitor_weight_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => viewModel.clearError(),
        ),

        const SizedBox(height: 20),

        // Mobility Level
        _buildLabel('Mobility Level *'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.selectedMobilityLevel,
              hint: const Text(
                'Select mobility level',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 32,
                color: Colors.blue[700],
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              items: viewModel.mobilityLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (String? newValue) {
                viewModel.setMobilityLevel(newValue);
                viewModel.clearError();
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Medical Conditions
        _buildLabel('Medical Conditions (Optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.medicalConditionsController,
          maxLines: 4,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'List any medical conditions, allergies, or concerns',
            hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
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
        ),
      ],
    );
  }

  // Helper: Section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Helper: Field label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // Helper: Standard text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 28, color: Colors.blue[700]),
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
      onChanged: onChanged,
    );
  }

  // Helper: Password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, size: 28, color: Colors.blue[700]),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 28,
            color: Colors.grey[600],
          ),
          onPressed: onToggle,
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
      onChanged: onChanged,
    );
  }

  // Handle registration
  Future<void> _handleRegister(
    BuildContext context,
    RegisterViewModel viewModel,
  ) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Call register method
    bool success = await viewModel.register();

    if (!success && context.mounted) {
      // Error message already shown in UI via viewModel.errorMessage
    }
  }
}
