import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _apiKey = AppConfig.geminiApiKey;

  // Classify issue using Gemini AI
  Future<Map<String, dynamic>> classifyIssue(String description, String? imagePath) async {
    try {
      final prompt = _buildClassificationPrompt(description, imagePath);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseClassificationResponse(generatedText);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      // Return default classification if Gemini fails
      return _getDefaultClassification(description);
    }
  }

  // Generate title from description
  Future<String> generateTitle(String description) async {
    try {
      final prompt = '''
Generate a concise, descriptive title (max 60 characters) for this complaint:

"$description"

Return only the title, no additional text.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 100,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      }
    } catch (e) {
      print('Title generation failed: $e');
    }
    
    return _generateDefaultTitle(description);
  }

  // Analyze sentiment
  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      final prompt = '''
Analyze the sentiment of this complaint text and return a JSON response:

Text: "$text"

Return JSON with:
- sentiment: "positive", "negative", or "neutral"
- score: number from -1.0 (very negative) to 1.0 (very positive)
- description: brief explanation

Example: {"sentiment": "negative", "score": -0.7, "description": "Expresses frustration and urgency"}
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseSentimentResponse(responseText);
      }
    } catch (e) {
      print('Sentiment analysis failed: $e');
    }
    
    return {
      'sentiment': 'neutral',
      'score': 0.0,
      'description': 'Sentiment analysis unavailable',
    };
  }

  // Suggest actions for resolution
  Future<List<String>> suggestActions({
    required String issueType,
    required String priority,
    String? description,
  }) async {
    try {
      final prompt = '''
Based on this complaint, suggest 3-5 specific actions for resolution:

Issue Type: $issueType
Priority: $priority
Description: ${description ?? 'Not provided'}

Return a JSON array of action strings.
Example: ["Inspect the location within 24 hours", "Contact the responsible department", "Schedule repair work"]
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 300,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseActionsResponse(responseText);
      }
    } catch (e) {
      print('Action suggestions failed: $e');
    }
    
    return _getDefaultActions(issueType, priority);
  }

  // Helper methods
  String _buildClassificationPrompt(String description, String? imagePath) {
    return '''
Analyze this complaint and provide structured information in JSON format:

Complaint Text: "$description"
${imagePath != null ? 'Image Available: Yes' : 'Image Available: No'}

Return JSON with:
- title: concise title (max 60 chars)
- category: one of [infrastructure, environment, safety, health, transportation, utilities, other]
- urgency: "low", "medium", or "high"
- confidence: number 0.0 to 1.0
- summary: brief summary (max 100 chars)
- suggested_department: appropriate department name
- keywords: array of important terms

Example:
{
  "title": "Pothole near Main Street intersection",
  "category": "infrastructure",
  "urgency": "medium",
  "confidence": 0.85,
  "summary": "Large pothole causing vehicle damage near Main Street intersection",
  "suggested_department": "Public Works Department",
  "keywords": ["pothole", "road", "intersection", "vehicle damage"]
}
''';
  }

  Map<String, dynamic> _parseClassificationResponse(String response) {
    try {
      // Try to extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        
        return {
          'title': data['title'] ?? 'Complaint',
          'category': data['category'] ?? 'other',
          'urgency': data['urgency'] ?? 'medium',
          'confidence': (data['confidence'] ?? 0.5).toDouble(),
          'summary': data['summary'] ?? '',
          'suggested_department': data['suggested_department'] ?? 'General Department',
          'keywords': List<String>.from(data['keywords'] ?? []),
        };
      }
    } catch (e) {
      print('Failed to parse Gemini response: $e');
    }
    
    // Fallback parsing
    return _getDefaultClassification(response);
  }

  Map<String, dynamic> _parseSentimentResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        
        return {
          'sentiment': data['sentiment'] ?? 'neutral',
          'score': (data['score'] ?? 0.0).toDouble(),
          'description': data['description'] ?? 'Sentiment analysis completed',
        };
      }
    } catch (e) {
      print('Failed to parse sentiment response: $e');
    }
    
    return {
      'sentiment': 'neutral',
      'score': 0.0,
      'description': 'Sentiment analysis unavailable',
    };
  }

  List<String> _parseActionsResponse(String response) {
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return List<String>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
      print('Failed to parse actions response: $e');
    }
    
    return ['Review complaint details', 'Assign to appropriate department', 'Schedule inspection'];
  }

  Map<String, dynamic> _getDefaultClassification(String description) {
    return {
      'title': _generateDefaultTitle(description),
      'category': 'other',
      'urgency': 'medium',
      'confidence': 0.5,
      'summary': description.length > 100 ? '${description.substring(0, 100)}...' : description,
      'suggested_department': 'General Department',
      'keywords': _extractKeywords(description),
    };
  }

  String _generateDefaultTitle(String description) {
    final words = description.split(' ');
    if (words.length <= 5) {
      return description;
    }
    return '${words.take(5).join(' ')}...';
  }

  List<String> _extractKeywords(String text) {
    final commonWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'};
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 3 && !commonWords.contains(word))
        .take(5)
        .toList();
  }

  List<String> _getDefaultActions(String issueType, String priority) {
    switch (issueType.toLowerCase()) {
      case 'infrastructure':
        return [
          'Inspect the reported location',
          'Assess damage severity',
          'Schedule repair work',
          'Update status to affected users',
        ];
      case 'environment':
        return [
          'Investigate environmental impact',
          'Contact environmental services',
          'Document findings',
          'Implement cleanup measures',
        ];
      case 'safety':
        return [
          'Immediate safety assessment',
          'Contact emergency services if needed',
          'Implement temporary safety measures',
          'Schedule permanent solution',
        ];
      default:
        return [
          'Review complaint details',
          'Assign to appropriate department',
          'Schedule inspection',
          'Provide status update',
        ];
    }
  }
}
