import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String _baseUrl = 'http://localhost:8000/api'; // iOS simulator

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Sign up with email and password
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'citizen',
  }) async {
    try {
      // Create Firebase user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = result.user;
      if (firebaseUser == null) return null;

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Store user profile in PostgreSQL via REST API
      await _storeUserProfile(
        firebaseUid: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Store user profile in PostgreSQL
  Future<void> _storeUserProfile({
    required String firebaseUid,
    required String name,
    required String email,
    String? phone,
    String role = 'citizen',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'firebase_uid': firebaseUid,
          'role': role,
          'phone': phone,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to store user profile: ${response.body}');
      }
    } catch (e) {
      print('Error storing user profile: $e');
      // Don't throw here - Firebase user is already created
    }
  }

  // Get user profile from PostgreSQL
  Future<CivicUser?> getUserProfile() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final idToken = await firebaseUser.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CivicUser.fromJson(data);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user's display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;
}

// Simple user model for the app
class CivicUser {
  final int userId;
  final String firebaseUid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const CivicUser({
    required this.userId,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.isActive = true,
    required this.createdAt,
  });

  factory CivicUser.fromJson(Map<String, dynamic> json) {
    return CivicUser(
      userId: json['user_id'],
      firebaseUid: json['firebase_uid'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
