import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YouTubeService {
  static String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Search for exercise tutorial video
  Future<String?> searchExerciseVideo(String exerciseName) async {
    try {
      // Build search query
      String query = 'elderly $exerciseName exercise tutorial';

      // Make API request
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'part': 'snippet',
          'q': query,
          'type': 'video',
          'maxResults': '5',
          'videoEmbeddable': 'true',
          'videoDuration': 'short',
          'order': 'relevance',
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          // Filter for professional channels
          for (var item in items) {
            String channelTitle = item['snippet']['channelTitle'] ?? '';
            String videoTitle = item['snippet']['title'] ?? '';
            String videoId = item['id']['videoId'] ?? '';

            // Prioritize professional/medical channels
            if (_isProfessionalChannel(channelTitle, videoTitle)) {
              return 'https://www.youtube.com/watch?v=$videoId';
            }
          }

          // If no professional channel found, return first result
          String videoId = items[0]['id']['videoId'];
          return 'https://www.youtube.com/watch?v=$videoId';
        }
      }

      return null;
    } catch (e) {
      print('YouTube search error: $e');
      return null;
    }
  }

  /// Check if channel/video is from professional source
  bool _isProfessionalChannel(String channelTitle, String videoTitle) {
    // List of trusted keywords
    List<String> professionalKeywords = [
      'physical therapy',
      'physiotherapy',
      'pt',
      'doctor',
      'dr.',
      'md',
      'clinic',
      'hospital',
      'rehab',
      'senior',
      'elderly',
      'aarp',
      'mayo clinic',
      'johns hopkins',
      'nih',
      'nhs',
      'health',
      'wellness',
      'fitness',
      'certified',
      'trainer',
    ];

    String combined =
        '${channelTitle.toLowerCase()} ${videoTitle.toLowerCase()}';

    for (String keyword in professionalKeywords) {
      if (combined.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Search for multiple videos and return best match
  Future<Map<String, String>> searchExerciseVideos(
    List<String> exerciseNames,
  ) async {
    Map<String, String> videos = {};

    for (String exerciseName in exerciseNames) {
      String? videoUrl = await searchExerciseVideo(exerciseName);
      if (videoUrl != null) {
        videos[exerciseName] = videoUrl;
      }

      // Add delay to respect API rate limits
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return videos;
  }
}
