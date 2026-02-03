import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OCRService {
  static String get _apiKey => dotenv.env['OCR_KEY'] ?? '';

  Future<String> extractTextFromImage(File imageFile) async {
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

    String cleanText = extractedText
        .replaceAll(RegExp(r'(?<=\d)[,;](?=\d{2})'), ':') // Fix 8,00 to 8:00
        .replaceAll('O', '0') // Fix letter O to zero
        .replaceAll('o', '0')
        .replaceAll('l', '1'); // Fix letter l to 1

    try {
      // Find dates
      List<DateTime> foundDates = [];

      // Numeric dates
      RegExp numericDate = RegExp(
        r'(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2,4}))?',
      );

      // Textual dates
      RegExp textDate = RegExp(r'(\d{1,2})\s+([a-zA-Z]+)\.?[\s,\.]+(\d{2,4})?');

      for (Match match in numericDate.allMatches(cleanText)) {
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

      // Find time
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

      // -Find location
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
        if (match.group(3) != null) {
          String yStr = match.group(3)!;
          year = yStr.length == 2 ? 2000 + int.parse(yStr) : int.parse(yStr);
        } else {
          DateTime now = DateTime.now();
          DateTime candidate = DateTime(year, month, day);
          if (candidate.isBefore(now.subtract(const Duration(days: 1)))) {
            year++;
          }
        }
      } else {
        month = _monthStringToInt(match.group(2)!);
        if (match.groupCount >= 3 && match.group(3) != null) {
          String yStr = match.group(3)!;
          year = yStr.length == 2 ? 2000 + int.parse(yStr) : int.parse(yStr);
        } else {
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
      } else {
        if (hour >= 7 && hour <= 11) {
        } else if (hour >= 1 && hour <= 5) {
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
