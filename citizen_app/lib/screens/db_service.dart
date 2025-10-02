import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import '../models/complaint.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class DatabaseService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Create a new complaint
  Future<Complaint> createComplaint({
    required String title,
    required String description,
    required String location,
    String? category,
    String? priority,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/complaints"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "location": location,
          "category": category,
          "priority": priority,
          "image_urls": imageUrls,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data["complaint"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/complaints"),
            headers: newHeaders,
            body: jsonEncode({
              "title": title,
              "description": description,
              "location": location,
              "category": category,
              "priority": priority,
              "image_urls": imageUrls,
              "latitude": latitude,
              "longitude": longitude,
            }),
          );
          
          if (retryResponse.statusCode == 201) {
            final data = jsonDecode(retryResponse.body);
            return Complaint.fromJson(data["complaint"]);
          }
        }
        throw Exception("Authentication failed");
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Failed to create complaint");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get complaints for the current user
  Future<List<Complaint>> getUserComplaints({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final queryParams = <String, String>{
        "page": page.toString(),
        "limit": limit.toString(),
        if (status != null) "status": status,
        if (category != null) "category": category,
      };
      
      final uri = Uri.parse("$baseUrl/complaints/my").replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data["complaints"] as List)
            .map((complaint) => Complaint.fromJson(complaint))
            .toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.get(uri, headers: newHeaders);
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return (data["complaints"] as List)
                .map((complaint) => Complaint.fromJson(complaint))
                .toList();
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to fetch complaints: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get all complaints (staff/admin only)
  Future<List<Complaint>> getAllComplaints({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final queryParams = <String, String>{
        "page": page.toString(),
        "limit": limit.toString(),
        if (status != null) "status": status,
        if (category != null) "category": category,
        if (priority != null) "priority": priority,
        if (assignedTo != null) "assigned_to": assignedTo,
      };
      
      final uri = Uri.parse("$baseUrl/complaints").replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data["complaints"] as List)
            .map((complaint) => Complaint.fromJson(complaint))
            .toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.get(uri, headers: newHeaders);
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return (data["complaints"] as List)
                .map((complaint) => Complaint.fromJson(complaint))
                .toList();
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. Staff or admin privileges required.");
      } else {
        throw Exception("Failed to fetch complaints: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Update complaint status (staff/admin only)
  Future<Complaint> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? notes,
    String? assignedTo,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse("$baseUrl/complaints/$complaintId/status"),
        headers: headers,
        body: jsonEncode({
          "status": status,
          "notes": notes,
          "assigned_to": assignedTo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data["complaint"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.put(
            Uri.parse("$baseUrl/complaints/$complaintId/status"),
            headers: newHeaders,
            body: jsonEncode({
              "status": status,
              "notes": notes,
              "assigned_to": assignedTo,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return Complaint.fromJson(data["complaint"]);
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. Staff or admin privileges required.");
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Failed to update complaint status");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Add comment to complaint
  Future<ComplaintComment> addComment({
    required String complaintId,
    required String comment,
    bool isInternal = false,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse("$baseUrl/complaints/$complaintId/comments"),
        headers: headers,
        body: jsonEncode({
          "comment": comment,
          "is_internal": isInternal,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ComplaintComment.fromJson(data["comment"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.post(
            Uri.parse("$baseUrl/complaints/$complaintId/comments"),
            headers: newHeaders,
            body: jsonEncode({
              "comment": comment,
              "is_internal": isInternal,
            }),
          );
          
          if (retryResponse.statusCode == 201) {
            final data = jsonDecode(retryResponse.body);
            return ComplaintComment.fromJson(data["comment"]);
          }
        }
        throw Exception("Authentication failed");
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Failed to add comment");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get complaint comments
  Future<List<ComplaintComment>> getComplaintComments({
    required String complaintId,
    bool includeInternal = false,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final queryParams = <String, String>{
        if (includeInternal) "include_internal": "true",
      };
      
      final uri = Uri.parse("$baseUrl/complaints/$complaintId/comments").replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data["comments"] as List)
            .map((comment) => ComplaintComment.fromJson(comment))
            .toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.get(uri, headers: newHeaders);
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return (data["comments"] as List)
                .map((comment) => ComplaintComment.fromJson(comment))
                .toList();
          }
        }
        throw Exception("Authentication failed");
      } else {
        throw Exception("Failed to fetch comments: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get complaint by ID
  Future<Complaint> getComplaintById(String complaintId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse("$baseUrl/complaints/$complaintId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data["complaint"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.get(
            Uri.parse("$baseUrl/complaints/$complaintId"),
            headers: newHeaders,
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return Complaint.fromJson(data["complaint"]);
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 404) {
        throw Exception("Complaint not found");
      } else {
        throw Exception("Failed to fetch complaint: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Get users (admin only)
  Future<List<User>> getUsers({
    int page = 1,
    int limit = 20,
    UserRole? role,
    bool? isActive,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final queryParams = <String, String>{
        "page": page.toString(),
        "limit": limit.toString(),
        if (role != null) "role": role.value,
        if (isActive != null) "is_active": isActive.toString(),
      };
      
      final uri = Uri.parse("$baseUrl/users").replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data["users"] as List)
            .map((user) => User.fromJson(user))
            .toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.get(uri, headers: newHeaders);
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return (data["users"] as List)
                .map((user) => User.fromJson(user))
                .toList();
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. Admin privileges required.");
      } else {
        throw Exception("Failed to fetch users: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  // Update user status (admin only)
  Future<User> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse("$baseUrl/users/$userId/status"),
        headers: headers,
        body: jsonEncode({
          "is_active": isActive,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data["user"]);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _authService.autoLogin();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = await _authService.getAuthHeaders();
          final retryResponse = await http.put(
            Uri.parse("$baseUrl/users/$userId/status"),
            headers: newHeaders,
            body: jsonEncode({
              "is_active": isActive,
            }),
          );
          
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return User.fromJson(data["user"]);
          }
        }
        throw Exception("Authentication failed");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. Admin privileges required.");
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Failed to update user status");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
}

// Complaint comment model
class ComplaintComment {
  final String id;
  final String complaintId;
  final String userId;
  final String userName;
  final String comment;
  final bool isInternal;
  final DateTime createdAt;

  const ComplaintComment({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.isInternal,
    required this.createdAt,
  });

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      id: json['id'] as String,
      complaintId: json['complaint_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      comment: json['comment'] as String,
      isInternal: json['is_internal'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'is_internal': isInternal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
