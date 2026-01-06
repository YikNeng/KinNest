import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';

class GeminiService {
  // Replace with your actual Gemini API key
  static const String _apiKey = 'AIzaSyAYY4gN2ioSPb4l9PIdmI5Pnsp3lrq2iK4';

  // UPDATED: Use correct model name and API version
  static const String _baseUrl = 'https://generativelanguage.googleapis.com';
  static const String _modelName = 'gemini-2.5-flash';

  String get _apiUrl => '$_baseUrl/v1/models/$_modelName:generateContent';

  /// Generate exercise routine using Gemini API
  Future<ExerciseRoutine> generateExerciseRoutine({
    required int age,
    required String healthCondition,
    required String mobilityLevel,
    required String durationType,
    required String intensity,
  }) async {
    try {
      // Build prompt
      String prompt = _buildPrompt(
        age: age,
        healthCondition: healthCondition,
        mobilityLevel: mobilityLevel,
        durationType: durationType,
        intensity: intensity,
      );

      print('Calling Gemini API...');
      print('Model: $_modelName');
      print('URL: $_apiUrl');

      // Make API request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 4096,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
          ],
        }),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('Error response body: ${response.body}');
        throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
      }

      // Parse response
      Map<String, dynamic> responseData = jsonDecode(response.body);
      print('Response received successfully');

      // Check if response has candidates
      if (responseData['candidates'] == null ||
          responseData['candidates'].isEmpty) {
        throw Exception('No response generated from Gemini API');
      }

      // Extract text from Gemini response
      String generatedText =
          responseData['candidates'][0]['content']['parts'][0]['text']
              .toString();

      print('Generated text length: ${generatedText.length}');
      print('RAW GEMINI OUTPUT:\n$generatedText');

      // Clean and parse JSON
      String cleanedJson = _extractJson(generatedText);
      print(
        'Cleaned JSON: ${cleanedJson.substring(0, cleanedJson.length > 200 ? 200 : cleanedJson.length)}...',
      );

      Map<String, dynamic> exerciseJson = jsonDecode(cleanedJson);

      // Create ExerciseRoutine from parsed JSON
      ExerciseRoutine routine = ExerciseRoutine.fromJson(exerciseJson);
      print(
        'Routine created successfully with ${routine.exercises.length} exercises',
      );

      return routine;
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Failed to parse exercise routine: Invalid JSON format');
    } catch (e) {
      print('Error generating exercise routine: $e');
      throw Exception('Failed to generate exercise routine: $e');
    }
  }

  /// Build structured prompt for Gemini
  String _buildPrompt({
    required int age,
    required String healthCondition,
    required String mobilityLevel,
    required String durationType,
    required String intensity,
  }) {
    String durationDescription = durationType == 'short'
        ? '15-30 minutes'
        : 'a daily/weekly long-term plan';

    String intensityDescription = intensity == 'low'
        ? 'very gentle and safe'
        : 'moderate but still safe for elderly';

    // Build health condition section
    String healthSection = _buildHealthConditionSection(healthCondition);

    // Build mobility section
    String mobilitySection = _buildMobilitySection(mobilityLevel);

    return '''
You are a professional physiotherapist specializing in elderly exercise programs.

PATIENT PROFILE:
- Age: $age years old
$healthSection
$mobilitySection

EXERCISE REQUIREMENTS:
- Duration: $durationDescription
- Intensity: $intensityDescription
- Must be safe for home use
- No equipment required
- Focus on fall prevention, balance, flexibility, and gentle strength

IMPORTANT SAFETY CONSTRAINTS:
- Avoid high-impact exercises
- Include proper warm-up and cool-down
- Provide clear safety notes for each exercise
- Emphasize listening to their body and stopping if pain occurs
- Exercises should be suitable for elderly individuals
- Consider general age-related limitations

LIMITATIONS:
- Generate EXACTLY 5 exercises only
- Each exercise must have at most 4 steps
- Keep descriptions concise

CRITICAL: You must respond with ONLY valid JSON. No markdown, no explanations, no extra text.

JSON STRUCTURE (respond with this exact format):
{
  "routine_type": "$durationType",
  "duration_minutes": 25,
  "exercises": [
    {
      "name": "Exercise Name",
      "description": "Brief description",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "duration_minutes": 5,
      "safety_notes": "Safety precautions"
    }
  ],
  "general_advice": "General advice for the user"
}

Generate the routine now in valid JSON format only. Start with { and end with }:
''';
  }

  /// Build health condition section of prompt
  String _buildHealthConditionSection(String healthCondition) {
    // Check if health condition is generic/empty
    if (healthCondition == 'No specific health conditions' ||
        healthCondition.toLowerCase().contains('no specific') ||
        healthCondition.toLowerCase().contains('none') ||
        healthCondition.trim().isEmpty) {
      return '- Health Condition: No specific health conditions reported (use general elderly safety guidelines)';
    }

    return '- Health Condition: $healthCondition (adjust exercises accordingly)';
  }

  /// Build mobility section of prompt
  String _buildMobilitySection(String mobilityLevel) {
    // Check if mobility level is generic/empty
    if (mobilityLevel == 'Normal mobility' ||
        mobilityLevel.toLowerCase().contains('normal') ||
        mobilityLevel.toLowerCase().contains('not specified') ||
        mobilityLevel.trim().isEmpty) {
      return '- Mobility Level: Normal mobility (standard elderly exercises)';
    }

    // Add specific guidance for limited mobility
    if (mobilityLevel.toLowerCase().contains('limited')) {
      return '- Mobility Level: $mobilityLevel (focus on seated exercises, avoid floor exercises, emphasize balance support)';
    }

    return '- Mobility Level: $mobilityLevel';
  }

  /// Extract JSON from Gemini response (handles markdown code blocks)
  String _extractJson(String text) {
    // Remove markdown code block markers if present
    String cleaned = text.trim();

    // Remove ```json and ``` markers
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // Find JSON object boundaries
    int start = cleaned.indexOf('{');
    int end = cleaned.lastIndexOf('}');

    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('Could not find valid JSON in response');
    }

    cleaned = cleaned.substring(start, end + 1);

    return cleaned;
  }

  /// NEW: Save routine to Firestore
  Future<String> saveRoutineToFirestore({
    required String userId,
    required ExerciseRoutine routine,
  }) async {
    try {
      // Reference to user's exercise routines collection
      final routinesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exerciseRoutines');

      // Delete existing routine (keep only latest)
      final existingRoutines = await routinesRef.get();
      for (var doc in existingRoutines.docs) {
        await doc.reference.delete();
      }

      // Save new routine
      final docRef = await routinesRef.add(routine.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save routine: $e');
    }
  }

  /// NEW: Load routine from Firestore
  Future<ExerciseRoutine?> loadRoutineFromFirestore({
    required String userId,
  }) async {
    try {
      // Reference to user's exercise routines collection
      final routinesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exerciseRoutines');

      // Get the latest routine (ordered by created_at)
      final snapshot = await routinesRef
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return ExerciseRoutine.fromFirestore(doc.id, doc.data());
    } catch (e) {
      throw Exception('Failed to load routine: $e');
    }
  }

  /// NEW: Delete routine from Firestore
  Future<void> deleteRoutineFromFirestore({
    required String userId,
    required String routineId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exerciseRoutines')
          .doc(routineId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete routine: $e');
    }
  }
}
