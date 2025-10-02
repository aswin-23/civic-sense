import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  final String baseUrl = AppConfig.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Storage keys
  static const String _tokenKey = "auth_token";
  static const String _userKey = "user_data";
  static const String _refreshTokenKey = "refresh_token";

  // Current user instance
  User? _currentUser;

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Save token securely
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Save refresh token
  Future<void> _saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // Save user data
  Future<void> _saveUser(User user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Check if token is valid and not expired
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  // Get user from stored data
  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData);
        _currentUser = User.fromJson(userJson);
        return _currentUser;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Auto-login on app launch
  Future<bool> autoLogin() async {
    final token = await getToken();
    if (token == null) return false;

    // Check if token is still valid
    if (await isTokenValid()) {
      // Get user data from storage
      final user = await getStoredUser();
      if (user != null) {
        _currentUser = user;
        return true;
      }
    }

    // Try to refresh token
    return await _refreshToken();
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/refresh"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data["token"]);
        if (data["refresh_token"] != null) {
          await _saveRefreshToken(data["refresh_token"]);
        }
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  // Signup with role
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role.value,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data["token"]);
        if (data["refresh_token"] != null) {
          await _saveRefreshToken(data["refresh_token"]);
        }
        
        final user = User.fromJson(data["user"]);
        await _saveUser(user);
        
        return AuthResult.success(user: user);
      } else {
        return AuthResult.error(message: data["message"] ?? "Signup failed");
      }
    } catch (e) {
      return AuthResult.error(message: "Network error: ${e.toString()}");
    }
  }

  // Login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data["token"]);
        if (data["refresh_token"] != null) {
          await _saveRefreshToken(data["refresh_token"]);
        }
        
        final user = User.fromJson(data["user"]);
        await _saveUser(user);
        
        return AuthResult.success(user: user);
      } else {
        return AuthResult.error(message: data["message"] ?? "Login failed");
      }
    } catch (e) {
      return AuthResult.error(message: "Network error: ${e.toString()}");
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Call logout endpoint to invalidate token on server
        await http.post(
          Uri.parse("$baseUrl/auth/logout"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      }
    } catch (e) {
      // Continue with local logout even if server call fails
    } finally {
      // Clear local storage
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
      _currentUser = null;
    }
  }

  // Get authenticated headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = {"Content-Type": "application/json"};
    
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    
    return headers;
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/auth/profile"),
        headers: headers,
        body: jsonEncode({
          if (name != null) "name": name,
          if (email != null) "email": email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(data["user"]);
        await _saveUser(user);
        return AuthResult.success(user: user);
      } else {
        return AuthResult.error(message: data["message"] ?? "Update failed");
      }
    } catch (e) {
      return AuthResult.error(message: "Network error: ${e.toString()}");
    }
  }

  // Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/auth/change-password"),
        headers: headers,
        body: jsonEncode({
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult.success();
      } else {
        return AuthResult.error(message: data["message"] ?? "Password change failed");
      }
    } catch (e) {
      return AuthResult.error(message: "Network error: ${e.toString()}");
    }
  }
}

// Auth result class for better error handling
class AuthResult {
  final bool isSuccess;
  final String? message;
  final User? user;

  const AuthResult._({
    required this.isSuccess,
    this.message,
    this.user,
  });

  factory AuthResult.success({User? user}) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error({required String message}) {
    return AuthResult._(isSuccess: false, message: message);
  }
}
