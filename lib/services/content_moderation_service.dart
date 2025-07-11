import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/content_moderation_config.dart';

class ContentModerationService {
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  /// Analyzes an image for inappropriate content
  /// Returns true if the image is safe, false if it contains inappropriate content
  Future<ContentModerationResult> analyzeImage(File imageFile) async {
    // Check if content moderation is enabled
    if (!ContentModerationConfig.enableContentModeration) {
      return ContentModerationResult(
        isAppropriate: true,
        adultContent: 1,
        violentContent: 1,
        racyContent: 1,
        medicalContent: 1,
        spoofContent: 1,
        details: 'Content moderation disabled',
      );
    }

    // Check if API key is configured
    if (ContentModerationConfig.apiKey == 'YOUR_GOOGLE_CLOUD_VISION_API_KEY') {
      print('Content moderation API key not configured. Skipping moderation.');
      return ContentModerationResult(
        isAppropriate: true,
        adultContent: 1,
        violentContent: 1,
        racyContent: 1,
        medicalContent: 1,
        spoofContent: 1,
        details: 'API key not configured - content moderation skipped',
      );
    }

    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the request
      final request = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'SAFE_SEARCH_DETECTION',
                'maxResults': 1,
              }
            ]
          }
        ]
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${ContentModerationConfig.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['responses'] != null && 
            responseData['responses'].isNotEmpty &&
            responseData['responses'][0]['safeSearchAnnotation'] != null) {
          
          final safeSearch = responseData['responses'][0]['safeSearchAnnotation'];
          
          // Check for inappropriate content
          final adult = _getLikelihoodScore(safeSearch['adult']);
          final violence = _getLikelihoodScore(safeSearch['violence']);
          final racy = _getLikelihoodScore(safeSearch['racy']);
          final medical = _getLikelihoodScore(safeSearch['medical']);
          final spoof = _getLikelihoodScore(safeSearch['spoof']);
          
          // Consider image inappropriate if any category is >= threshold
          final threshold = ContentModerationConfig.contentThreshold;
          final isInappropriate = adult >= threshold || violence >= threshold || racy >= threshold;
          
          return ContentModerationResult(
            isAppropriate: !isInappropriate,
            adultContent: adult,
            violentContent: violence,
            racyContent: racy,
            medicalContent: medical,
            spoofContent: spoof,
            details: _getContentDetails(safeSearch),
          );
        }
      } else if (response.statusCode == 400) {
        // API key not configured or invalid
        print('Content moderation API error: ${response.body}');
        return ContentModerationResult(
          isAppropriate: true,
          adultContent: 1,
          violentContent: 1,
          racyContent: 1,
          medicalContent: 1,
          spoofContent: 1,
          details: 'API error - content moderation skipped',
        );
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in content moderation: $e');
      // In case of error, we'll be permissive and allow the image
      // but log the error for debugging
      return ContentModerationResult(
        isAppropriate: true,
        adultContent: 1,
        violentContent: 1,
        racyContent: 1,
        medicalContent: 1,
        spoofContent: 1,
        details: 'Error during analysis: $e',
      );
    }
    
    // Default case - allow image
    return ContentModerationResult(
      isAppropriate: true,
      adultContent: 1,
      violentContent: 1,
      racyContent: 1,
      medicalContent: 1,
      spoofContent: 1,
      details: 'No analysis performed',
    );
  }

  /// Converts Google's likelihood string to a numerical score
  /// 1: VERY_UNLIKELY, 2: UNLIKELY, 3: POSSIBLE, 4: LIKELY, 5: VERY_LIKELY
  int _getLikelihoodScore(String? likelihood) {
    switch (likelihood?.toUpperCase()) {
      case 'VERY_UNLIKELY':
        return 1;
      case 'UNLIKELY':
        return 2;
      case 'POSSIBLE':
        return 3;
      case 'LIKELY':
        return 4;
      case 'VERY_LIKELY':
        return 5;
      default:
        return 1; // Default to very unlikely
    }
  }

  /// Gets human-readable content details
  String _getContentDetails(Map<String, dynamic> safeSearch) {
    final details = <String>[];
    final threshold = ContentModerationConfig.contentThreshold;
    
    if (_getLikelihoodScore(safeSearch['adult']) >= threshold) {
      details.add('adult content');
    }
    if (_getLikelihoodScore(safeSearch['violence']) >= threshold) {
      details.add('violent content');
    }
    if (_getLikelihoodScore(safeSearch['racy']) >= threshold) {
      details.add('racy content');
    }
    
    if (details.isEmpty) {
      return 'Content appears appropriate';
    } else {
      return 'Detected: ${details.join(', ')}';
    }
  }
}

/// Result of content moderation analysis
class ContentModerationResult {
  final bool isAppropriate;
  final int adultContent;
  final int violentContent;
  final int racyContent;
  final int medicalContent;
  final int spoofContent;
  final String details;

  ContentModerationResult({
    required this.isAppropriate,
    required this.adultContent,
    required this.violentContent,
    required this.racyContent,
    required this.medicalContent,
    required this.spoofContent,
    required this.details,
  });

  @override
  String toString() {
    return 'ContentModerationResult(isAppropriate: $isAppropriate, details: $details)';
  }
} 