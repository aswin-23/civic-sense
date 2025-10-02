// ✅ All imports at the very top
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String _baseUrl = 'http://localhost:8000/api'; // iOS simulator

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔑 Get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final idToken = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  // 📌 Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'API request failed');
      } catch (_) {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    }
  }

  // 📝 Create complaint
  Future<Complaint> createComplaint({
    required String title,
    required String description,
    required String issueType,
    required double locationLat,
    required double locationLng,
    String? imageUrl,
    String? city,
    String? zone,
    String priority = 'medium',
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/complaints'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'issue_type': issueType,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'image_url': imageUrl,
        'city': city,
        'zone': zone,
        'priority': priority,
      }),
    );

    final data = _handleResponse(response);
    return Complaint.fromJson(data as Map<String, dynamic>);
  }

  // 📌 Fetch user's complaints
  Future<List<Complaint>> fetchUserIssues() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/complaints'),
      headers: headers,
    );

    final data = _handleResponse(response);
    if (data is List) {
      return data.map((json) => Complaint.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // 📌 Fetch assigned complaints (for staff)
  Future<List<Complaint>> getAssignedComplaints() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/complaints/assigned'),
      headers: headers,
    );

    final data = _handleResponse(response);
    if (data is List) {
      return data.map((json) => Complaint.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // 🔄 Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? remarks,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/complaints/$complaintId/status'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'remarks': remarks,
      }),
    );

    _handleResponse(response);
  }

  // 👤 Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data as Map<String, dynamic>;
  }

  // 💓 Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$_baseUrl/health'));
    final data = _handleResponse(response);
    return data as Map<String, dynamic>;
  }

  // 🔍 Get complaint by ID
  Future<Complaint> getComplaintById(String complaintId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/complaints/$complaintId'),
      headers: headers,
    );

    final data = _handleResponse(response);
    return Complaint.fromJson(data as Map<String, dynamic>);
  }

  // 🗑️ Delete complaint
  Future<void> deleteComplaint(String complaintId) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/complaints/$complaintId'),
      headers: headers,
    );

    _handleResponse(response);
  }

  // 📜 Complaint history
  Future<List<Map<String, dynamic>>> getComplaintHistory(String complaintId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/complaints/$complaintId/history'),
      headers: headers,
    );

    final data = _handleResponse(response);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  // 🔎 Search complaints
  Future<List<Complaint>> searchComplaints({
    String? query,
    String? status,
    String? category,
    int? limit,
    int? offset,
  }) async {
    final headers = await _getAuthHeaders();
    final queryParams = <String, String>{};

    if (query != null) queryParams['q'] = query;
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$_baseUrl/complaints/search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);

    final data = _handleResponse(response);
    if (data is List) {
      return data.map((json) => Complaint.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
