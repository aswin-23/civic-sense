import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import '../config/app_config.dart';

class GeminiService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Classify complaint text using Gemini AI
  Future<ComplaintClassification> classifyComplaint({
    required String complaintText,
    String? location,
    String? category,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/gemini/classify"),
        headers: headers,
        body: jsonEncode({
          "text": complaintText,
          "location": location,
          "category": category,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ComplaintClassification.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/gemini/classify"),
            headers: newHeaders,
            body: jsonEncode({
              "text": complaintText,
              "location": location,
              "category": category,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return ComplaintClassification.fromJson(data);
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to classify complaint: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Generate complaint summary using Gemini AI
  Future<String> generateComplaintSummary({
    required String complaintText,
    String? location,
    String? category,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/gemini/summarize"),
        headers: headers,
        body: jsonEncode({
          "text": complaintText,
          "location": location,
          "category": category,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["summary"] as String;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/gemini/summarize"),
            headers: newHeaders,
            body: jsonEncode({
              "text": complaintText,
              "location": location,
              "category": category,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return data["summary"] as String;
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to generate summary: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get suggested actions for a complaint
  Future<List<String>> getSuggestedActions({
    required String complaintText,
    String? category,
    String? priority,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/gemini/suggest-actions"),
        headers: headers,
        body: jsonEncode({
          "text": complaintText,
          "category": category,
          "priority": priority,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data["actions"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/gemini/suggest-actions"),
            headers: newHeaders,
            body: jsonEncode({
              "text": complaintText,
              "category": category,
              "priority": priority,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return List<String>.from(data["actions"]);
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to get suggested actions: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Analyze complaint sentiment
  Future<SentimentAnalysis> analyzeSentiment({
    required String complaintText,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/gemini/sentiment"),
        headers: headers,
        body: jsonEncode({
          "text": complaintText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SentimentAnalysis.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/gemini/sentiment"),
            headers: newHeaders,
            body: jsonEncode({
              "text": complaintText,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return SentimentAnalysis.fromJson(data);
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to analyze sentiment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get analytics data (admin only)
  Future<ComplaintAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? location,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/gemini/analytics"),
        headers: headers,
        body: jsonEncode({
          if (startDate != null) "start_date": startDate.toIso8601String(),
          if (endDate != null) "end_date": endDate.toIso8601String(),
          if (category != null) "category": category,
          if (location != null) "location": location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ComplaintAnalytics.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/gemini/analytics"),
            headers: newHeaders,
            body: jsonEncode({
              if (startDate != null) "start_date": startDate.toIso8601String(),
              if (endDate != null) "end_date": endDate.toIso8601String(),
              if (category != null) "category": category,
              if (location != null) "location": location,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return ComplaintAnalytics.fromJson(data);
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. Admin privileges required.");
      } else {
        throw Exception("Failed to get analytics: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
}

// Data models for Gemini service responses
class ComplaintClassification {
  final String category;
  final String priority;
  final double confidence;
  final List<String> keywords;
  final String suggestedDepartment;

  const ComplaintClassification({
    required this.category,
    required this.priority,
    required this.confidence,
    required this.keywords,
    required this.suggestedDepartment,
  });

  factory ComplaintClassification.fromJson(Map<String, dynamic> json) {
    return ComplaintClassification(
      category: json['category'] as String,
      priority: json['priority'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      keywords: List<String>.from(json['keywords']),
      suggestedDepartment: json['suggested_department'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'priority': priority,
      'confidence': confidence,
      'keywords': keywords,
      'suggested_department': suggestedDepartment,
    };
  }
}

class SentimentAnalysis {
  final String sentiment; // positive, negative, neutral
  final double score; // -1 to 1
  final String description;

  const SentimentAnalysis({
    required this.sentiment,
    required this.score,
    required this.description,
  });

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      sentiment: json['sentiment'] as String,
      score: (json['score'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentiment': sentiment,
      'score': score,
      'description': description,
    };
  }
}

class ComplaintAnalytics {
  final int totalComplaints;
  final Map<String, int> complaintsByCategory;
  final Map<String, int> complaintsByPriority;
  final Map<String, int> complaintsByStatus;
  final List<ComplaintTrend> trends;
  final String insights;

  const ComplaintAnalytics({
    required this.totalComplaints,
    required this.complaintsByCategory,
    required this.complaintsByPriority,
    required this.complaintsByStatus,
    required this.trends,
    required this.insights,
  });

  factory ComplaintAnalytics.fromJson(Map<String, dynamic> json) {
    return ComplaintAnalytics(
      totalComplaints: json['total_complaints'] as int,
      complaintsByCategory: Map<String, int>.from(json['complaints_by_category']),
      complaintsByPriority: Map<String, int>.from(json['complaints_by_priority']),
      complaintsByStatus: Map<String, int>.from(json['complaints_by_status']),
      trends: (json['trends'] as List)
          .map((trend) => ComplaintTrend.fromJson(trend))
          .toList(),
      insights: json['insights'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_complaints': totalComplaints,
      'complaints_by_category': complaintsByCategory,
      'complaints_by_priority': complaintsByPriority,
      'complaints_by_status': complaintsByStatus,
      'trends': trends.map((trend) => trend.toJson()).toList(),
      'insights': insights,
    };
  }
}

class ComplaintTrend {
  final DateTime date;
  final int count;
  final String category;

  const ComplaintTrend({
    required this.date,
    required this.count,
    required this.category,
  });

  factory ComplaintTrend.fromJson(Map<String, dynamic> json) {
    return ComplaintTrend(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'count': count,
      'category': category,
    };
  }
}
