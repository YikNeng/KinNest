import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OCRService {
  // IMPORTANT: In production, store API key securely (e.g., environment variables, Firebase Remote Config)
  // DO NOT hardcode API keys in source code
  static const String _apiKey = 'YOUR_GOOGLE_CLOUD_VISION_API_KEY';

  /// Extract text from medical card image using Google Cloud Vision OCR
  /// Returns extracted text
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Read image file as base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Google Cloud Vision API endpoint
      String url =
          'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

      // Request body
      Map<String, dynamic> requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION', 'maxResults': 1},
            ],
          },
        ],
      };

      // Make API call
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract full text annotation
        if (responseData['responses'] != null &&
            responseData['responses'].isNotEmpty) {
          var textAnnotations = responseData['responses'][0]['textAnnotations'];
          if (textAnnotations != null && textAnnotations.isNotEmpty) {
            String extractedText = textAnnotations[0]['description'];
            return extractedText;
          }
        }

        throw Exception('No text detected in image');
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Parse appointment details from extracted text
  /// Returns map with parsed date and time (as Map for time)
  Map<String, dynamic> parseAppointmentDetails(String extractedText) {
    Map<String, dynamic> result = {'date': null, 'time': null};

    try {
      // Simple regex patterns for date and time
      // Format: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD
      RegExp datePattern = RegExp(
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})',
      );

      // Format: HH:MM AM/PM, HH:MM
      RegExp timePattern = RegExp(
        r'(\d{1,2}:\d{2}\s?(?:AM|PM|am|pm)?)',
        caseSensitive: false,
      );

      // Find date
      Match? dateMatch = datePattern.firstMatch(extractedText);
      if (dateMatch != null) {
        result['date'] = _parseDate(dateMatch.group(0)!);
      }

      // Find time
      Match? timeMatch = timePattern.firstMatch(extractedText);
      if (timeMatch != null) {
        result['time'] = _parseTime(timeMatch.group(0)!);
      }

      return result;
    } catch (e) {
      return result;
    }
  }

  /// Parse date string to DateTime
  DateTime? _parseDate(String dateString) {
    try {
      // Try different date formats
      List<RegExp> formats = [
        RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'), // DD/MM/YYYY
        RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY-MM-DD
      ];

      for (var format in formats) {
        Match? match = format.firstMatch(dateString);
        if (match != null) {
          if (dateString.startsWith(RegExp(r'\d{4}'))) {
            // YYYY-MM-DD
            int year = int.parse(match.group(1)!);
            int month = int.parse(match.group(2)!);
            int day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
            // DD/MM/YYYY
            int day = int.parse(match.group(1)!);
            int month = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Parse time string to Map with hour and minute
  /// Returns: {'hour': int, 'minute': int} or null
  Map<String, int>? _parseTime(String timeString) {
    try {
      // Remove spaces
      timeString = timeString.replaceAll(' ', '');

      // Check for AM/PM
      bool isPM = timeString.toUpperCase().contains('PM');
      bool isAM = timeString.toUpperCase().contains('AM');

      // Extract hour and minute
      RegExp timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
      Match? match = timeRegex.firstMatch(timeString);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);

        // Convert to 24-hour format if PM
        if (isPM && hour < 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }

        return {'hour': hour, 'minute': minute};
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
