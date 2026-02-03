import 'package:flutter/material.dart';
import 'package:latest_fyp/views/elderly/elderly_exercise_routine_page.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/exercise_viewmodel.dart';

class ElderlyExercisePage extends StatefulWidget {
  final bool skipAutoNavigate;

  const ElderlyExercisePage({super.key, this.skipAutoNavigate = false});

  @override
  State<ElderlyExercisePage> createState() => _ElderlyExercisePageState();
}

class _ElderlyExercisePageState extends State<ElderlyExercisePage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExerciseViewModel>(context);
    if (viewModel.generatedRoutine != null && !widget.skipAutoNavigate) {
      return const ElderlyExerciseRoutinePage();
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Exercise Routine',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: viewModel.isLoading
          ? _buildLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // Error message
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel),

                  // Profile Summary
                  _buildProfileSummary(viewModel),

                  const SizedBox(height: 32),

                  // Duration Type Selection
                  _buildDurationTypeSection(context, viewModel),

                  const SizedBox(height: 32),

                  // Intensity Selection
                  _buildIntensitySection(context, viewModel),

                  const SizedBox(height: 40),

                  // Generate Button
                  _buildGenerateButton(context, viewModel),
                ],
              ),
            ),
    );
  }

  Future<void> _handleGenerate(
    BuildContext context,
    ExerciseViewModel viewModel,
  ) async {
    bool success = await viewModel.generateRoutine();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green[700], strokeWidth: 4),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.fitness_center, size: 80, color: Colors.green[700]),
        const SizedBox(height: 16),
        const Text(
          'Get Your Personal\nExercise Routine',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'AI-generated exercises tailored just for you',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ExerciseViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[900]),
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

  Widget _buildProfileSummary(ExerciseViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Your Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileItem(
            'Age',
            viewModel.userAge?.toString() ?? 'Not set',
            Icons.cake,
            isRequired: true,
            isMissing: viewModel.userAge == null,
          ),
          const SizedBox(height: 12),
          _buildProfileItem(
            'Health Condition',
            viewModel.medicalConditionsDisplay,
            Icons.favorite,
            isRequired: false,
            isMissing: false,
          ),
          const SizedBox(height: 12),
          _buildProfileItem(
            'Mobility Level',
            viewModel.mobilityLevelDisplay,
            Icons.accessibility_new,
            isRequired: false,
            isMissing: false,
          ),
          if (viewModel.userAge == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please set your age in profile to generate exercises',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (viewModel.userAge != null &&
              (viewModel.userMedicalConditions == null ||
                  viewModel.userMobilityLevel == null)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Exercises will be based on general elderly guidelines',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    String label,
    String value,
    IconData icon, {
    bool isRequired = false,
    bool isMissing = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isMissing ? Colors.orange[700] : Colors.blue[700],
        ),
        const SizedBox(width: 12),

        SizedBox(
          width: 140,
          child: Text(
            '$label: ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isMissing ? Colors.orange[800] : Colors.blue[800],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              color: isMissing ? Colors.orange[900] : Colors.blue[900],
              fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationTypeSection(
    BuildContext context,
    ExerciseViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer, size: 28, color: Colors.grey[800]),
            const SizedBox(width: 12),
            const Text(
              'Routine Duration',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDurationOption(
          context,
          viewModel,
          'Short Routine',
          '15-30 minutes',
          'short',
          Icons.access_time,
        ),
        const SizedBox(height: 12),
        _buildDurationOption(
          context,
          viewModel,
          'Long-term Plan',
          'Daily/weekly schedule',
          'long_term',
          Icons.calendar_month,
        ),
      ],
    );
  }

  Widget _buildDurationOption(
    BuildContext context,
    ExerciseViewModel viewModel,
    String title,
    String subtitle,
    String value,
    IconData icon,
  ) {
    bool isSelected = viewModel.durationType == value;

    return InkWell(
      onTap: () => viewModel.setDurationType(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green[900] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green[700], size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySection(
    BuildContext context,
    ExerciseViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 28, color: Colors.grey[800]),
            const SizedBox(width: 12),
            const Text(
              'Exercise Intensity',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildIntensityOption(
          context,
          viewModel,
          'Low',
          'Gentle and very safe',
          'low',
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildIntensityOption(
          context,
          viewModel,
          'Medium',
          'Moderate but safe',
          'medium',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildIntensityOption(
    BuildContext context,
    ExerciseViewModel viewModel,
    String title,
    String subtitle,
    String value,
    MaterialColor color,
  ) {
    bool isSelected = viewModel.intensity == value;

    return InkWell(
      onTap: () => viewModel.setIntensity(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color[700]! : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  value == 'low' ? 'L' : 'M',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color[900] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? color[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color[700], size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    ExerciseViewModel viewModel,
  ) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: viewModel.isGenerating
            ? null
            : () => _handleGenerate(context, viewModel),
        icon: viewModel.isGenerating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.auto_awesome, size: 28),
        label: Text(
          viewModel.isGenerating
              ? 'Generating...'
              : viewModel.generatedRoutine != null
              ? 'Generate New Routine'
              : 'Generate Exercise Routine',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
