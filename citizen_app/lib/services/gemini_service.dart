import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCJd-hI7VfMPP40NpZU62J8tF-q9BF8WVE';

  /// Process complaint data using Gemini API
  /// Returns a Map with processed complaint information
  static Future<Map<String, dynamic>> processComplaint(Map<String, dynamic> input) async {
    try {
      // Initialize the GenerativeModel with the correct model name
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      // Prepare the prompt for Gemini
      final prompt = _buildPrompt(input);
      
      // Generate content using the model
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        return _parseGeminiResponse(response.text!, input);
      } else {
        throw Exception('No response from Gemini API');
      }
    } catch (e) {
      throw Exception('Failed to process complaint with Gemini: $e');
    }
  }

  /// Build the prompt for Gemini API
  static String _buildPrompt(Map<String, dynamic> input) {
    final description = input['description'] ?? '';
    final location = input['location'] ?? {};
    final media = input['media'] ?? [];
    final audioTranscription = input['audio_transcription'] ?? '';

    return '''
Analyze this civic complaint and generate a structured response with the following fields:

Complaint Description: $description
Audio Transcription: $audioTranscription
Location: ${location['lat']}, ${location['long']}
Media Files: ${media.join(', ')}

Please generate a JSON response with these exact fields:
{
  "complaint_id": "Generate a unique ID like COMP-YYYYMMDD-XXXX",
  "complaint_title": "Create a concise title based on the description",
  "status": "submitted",
  "submitted_at": "${DateTime.now().toIso8601String()}",
  "department": "Determine appropriate department (e.g., Public Works, Traffic, Sanitation, etc.)",
  "mobile_number": "Extract or suggest a mobile number if mentioned, otherwise leave empty",
  "priority": "Determine priority level (low/medium/high) based on description",
  "category": "Categorize the complaint (e.g., Infrastructure, Safety, Environment, etc.)"
}

Return only the JSON object, no additional text.
''';
  }

  /// Parse Gemini API response and extract the JSON
  static Map<String, dynamic> _parseGeminiResponse(String responseText, Map<String, dynamic> originalInput) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('No JSON found in Gemini response');
      }

      final jsonString = jsonMatch.group(0)!;
      final parsedResponse = jsonDecode(jsonString) as Map<String, dynamic>;

      // Merge with original input to preserve media and location data
      return {
        ...parsedResponse,
        'original_description': originalInput['description'],
        'location': originalInput['location'],
        'media': originalInput['media'],
        'audio_transcription': originalInput['audio_transcription'],
      };
    } catch (e) {
      // If parsing fails, return a default structure
      return _createDefaultResponse(originalInput);
    }
  }

  /// Create a default response if Gemini parsing fails
  static Map<String, dynamic> _createDefaultResponse(Map<String, dynamic> input) {
    final now = DateTime.now();
    final complaintId = 'COMP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    
    return {
      'complaint_id': complaintId,
      'complaint_title': 'Civic Issue Report',
      'status': 'submitted',
      'submitted_at': now.toIso8601String(),
      'department': 'General',
      'mobile_number': '',
      'priority': 'medium',
      'category': 'General',
      'original_description': input['description'],
      'location': input['location'],
      'media': input['media'],
      'audio_transcription': input['audio_transcription'],
    };
  }

  /// Test the Gemini API connection
  static Future<bool> testConnection() async {
    try {
      final testInput = {
        'description': 'Test complaint',
        'location': {'lat': 0.0, 'long': 0.0},
        'media': [],
        'audio_transcription': '',
      };
      
      await processComplaint(testInput);
      return true;
    } catch (e) {
      return false;
    }
  }
}