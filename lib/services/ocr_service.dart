import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OCRService {
  // IMPORTANT: In production, store API key securely
  static const String _apiKey = 'AIzaSyCXwqMm6td2qLtj07WouZgBzNCIkySAB5E';

  Future<String> extractTextFromImage(File imageFile) async {
    // ... (Keep this method exactly the same as before) ...
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      String url =
          'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

      Map<String, dynamic> requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
            ],
            'imageContext': {
              'languageHints': ['en', 'ms'],
            },
          },
        ],
      };

      http.Response response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['responses'] != null &&
            responseData['responses'].isNotEmpty) {
          var responseItem = responseData['responses'][0];

          if (responseItem['fullTextAnnotation'] != null) {
            return responseItem['fullTextAnnotation']['text'];
          } else if (responseItem['textAnnotations'] != null &&
              responseItem['textAnnotations'].isNotEmpty) {
            return responseItem['textAnnotations'][0]['description'];
          }
        }
        return "";
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Parse appointment details
  Map<String, dynamic> parseAppointmentDetails(String extractedText) {
    Map<String, dynamic> result = {
      'date': null,
      'time': null,
      'location': null,
    };

    // 1. CLEANING: Fix common OCR handwriting mistakes before parsing
    String cleanText = extractedText
        .replaceAll(RegExp(r'(?<=\d)[,;](?=\d{2})'), ':') // Fix 8,00 to 8:00
        .replaceAll('O', '0') // Fix letter O to zero
        .replaceAll('o', '0')
        .replaceAll('l', '1'); // Fix letter l to 1

    try {
      // --- 1. FIND DATES (Updated for Short Dates) ---
      List<DateTime> foundDates = [];

      // Pattern A: Numeric (supports 14/5/2023 AND 14/5)
      // Group 3 (Year) is now optional (?)
      RegExp numericDate = RegExp(
        r'(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2,4}))?',
      );

      // Pattern B: Text (12 Oct 2023 OR 12 Oct)
      RegExp textDate = RegExp(r'(\d{1,2})\s+([a-zA-Z]+)\.?[\s,\.]+(\d{2,4})?');

      for (Match match in numericDate.allMatches(cleanText)) {
        // Filter: If it matches, ensure it's not just a time (like 8/10 for 8:10)
        // Simple check: Month must be <= 12, Day <= 31
        DateTime? dt = _parseDateFuzzy(match, isNumeric: true);
        if (dt != null) foundDates.add(dt);
      }

      for (Match match in textDate.allMatches(cleanText)) {
        if (_isValidMonth(match.group(2)!)) {
          DateTime? dt = _parseDateFuzzy(match, isNumeric: false);
          if (dt != null) foundDates.add(dt);
        }
      }

      if (foundDates.isNotEmpty) {
        foundDates.sort((a, b) => a.compareTo(b));
        result['date'] = foundDates.last;
      }

      // --- 2. FIND TIME (With "Medical Logic") ---
      RegExp timePattern = RegExp(
        r'(\d{1,2})[:\.]?(\d{2})?\s*([ap]\.?m\.?|pg|pagi|ptg|petang|tgh|mlm|malam)?',
        caseSensitive: false,
      );

      for (Match match in timePattern.allMatches(cleanText)) {
        if (match.group(2) == null && match.group(3) == null) continue;

        var time = _parseTimeWithSmartLogic(match); // Using new "Smart Logic"
        if (time != null) {
          result['time'] = time;
          if (match.group(3) != null) break;
        }
      }

      // --- 3. LOCATION ---
      // (Same location logic as before)
      List<String> lines = cleanText.split('\n');
      List<String> locationKeywords = [
        'hospital',
        'clinic',
        'klinik',
        'medical',
        'pusat',
        'specialist',
        'centre',
        'center',
        'dental',
        'doctor',
        'dr.',
        'poliklinik',
        'farmasi',
      ];

      for (String line in lines) {
        String lowerLine = line.toLowerCase();
        if (locationKeywords.any((k) => lowerLine.contains(k))) {
          String candidate = line.trim();
          if (candidate.length > 5 && !candidate.contains(RegExp(r'^\d'))) {
            result['location'] = candidate;
            break;
          }
        }
      }

      return result;
    } catch (e) {
      return result;
    }
  }

  DateTime? _parseDateFuzzy(Match match, {required bool isNumeric}) {
    try {
      int day = int.parse(match.group(1)!);
      int month = 1;
      int year = DateTime.now().year; // Default to current year

      if (isNumeric) {
        month = int.parse(match.group(2)!);
        // Check if Year (Group 3) exists
        if (match.group(3) != null) {
          String yStr = match.group(3)!;
          year = yStr.length == 2 ? 2000 + int.parse(yStr) : int.parse(yStr);
        } else {
          // No year provided (e.g. 14/5).
          // Logic: If 14/5 has already passed this year, assume next year.
          DateTime now = DateTime.now();
          DateTime candidate = DateTime(year, month, day);
          if (candidate.isBefore(now.subtract(const Duration(days: 1)))) {
            year++; // Move to next year
          }
        }
      } else {
        month = _monthStringToInt(match.group(2)!);
        if (match.groupCount >= 3 && match.group(3) != null) {
          String yStr = match.group(3)!;
          year = yStr.length == 2 ? 2000 + int.parse(yStr) : int.parse(yStr);
        } else {
          // Same logic for text dates without year
          DateTime now = DateTime.now();
          DateTime candidate = DateTime(year, month, day);
          if (candidate.isBefore(now.subtract(const Duration(days: 1)))) {
            year++;
          }
        }
      }

      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  Map<String, int>? _parseTimeWithSmartLogic(Match match) {
    try {
      int hour = int.parse(match.group(1)!);
      int minute = 0;

      if (match.group(2) != null) {
        minute = int.parse(match.group(2)!);
      }

      String? suffix = match.group(3)?.toLowerCase().replaceAll('.', '');

      // If suffix detected, trust it
      if (suffix != null) {
        bool isPM = [
          'pm',
          'ptg',
          'petang',
          'tgh',
          'tengahari',
          'mlm',
          'malam',
        ].contains(suffix);
        bool isAM = ['am', 'pg', 'pagi'].contains(suffix);

        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
      }
      // NEW: "Medical Logic" Fallback
      // If NO suffix is found (e.g., just "8:00"), assume AM for typical morning hours
      // because appointments are rarely at 8:00 PM without specifically saying PM.
      else {
        if (hour >= 7 && hour <= 11) {
          // Assume AM for 7-11 (7am - 11am)
          // No change needed as hour is already correct
        } else if (hour >= 1 && hour <= 5) {
          // Assume PM for 1-5 (1pm - 5pm)
          hour += 12;
        }
      }

      // Basic validation
      if (hour > 23 || minute > 59) return null;

      return {'hour': hour, 'minute': minute};
    } catch (e) {
      return null;
    }
  }

  // ... (Keep _isValidMonth and _monthStringToInt same as before)
  bool _isValidMonth(String text) {
    return _monthStringToInt(text) != 0;
  }

  int _monthStringToInt(String month) {
    String m = month.toLowerCase().trim();
    if (m.startsWith('jan')) return 1;
    if (m.startsWith('feb')) return 2;
    if (m.startsWith('mar') || m.startsWith('mac')) return 3;
    if (m.startsWith('apr')) return 4;
    if (m.startsWith('may') || m.startsWith('mei')) return 5;
    if (m.startsWith('jun')) return 6;
    if (m.startsWith('jul')) return 7;
    if (m.startsWith('aug') || m.startsWith('ogo')) return 8;
    if (m.startsWith('sep')) return 9;
    if (m.startsWith('oct') || m.startsWith('okt')) return 10;
    if (m.startsWith('nov')) return 11;
    if (m.startsWith('dec') || m.startsWith('dis')) return 12;
    return 0;
  }
}
