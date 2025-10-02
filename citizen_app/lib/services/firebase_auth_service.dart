import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _userKey = "user_data";

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);
        
        // Create custom user object
        final customUser = User(
          id: result.user!.uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Save user data to secure storage
        await _saveUserData(customUser);

        return AuthResult.success(user: customUser);
      } else {
        return AuthResult.error(message: "Failed to create user");
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult.error(message: "An unexpected error occurred");
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user data from storage or create new
        final customUser = await _getUserData(result.user!.uid) ?? User(
          id: result.user!.uid,
          name: result.user!.displayName ?? 'User',
          email: result.user!.email ?? '',
          role: UserRole.citizen,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Update last login
        final updatedUser = customUser.copyWith(lastLoginAt: DateTime.now());
        await _saveUserData(updatedUser);

        return AuthResult.success(user: updatedUser);
      } else {
        return AuthResult.error(message: "Failed to sign in");
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult.error(message: "An unexpected error occurred");
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.error(message: "Google sign-in cancelled");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        final customUser = User(
          id: result.user!.uid,
          name: result.user!.displayName ?? 'User',
          email: result.user!.email ?? '',
          role: UserRole.citizen,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
        );

        await _saveUserData(customUser);
        return AuthResult.success(user: customUser);
      } else {
        return AuthResult.error(message: "Failed to sign in with Google");
      }
    } catch (e) {
      return AuthResult.error(message: "Google sign-in failed: ${e.toString()}");
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _storage.delete(key: _userKey);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult.error(message: "Failed to send reset email");
    }
  }

  // Update password
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult.error(message: "Failed to update password");
    }
  }

  // Update profile
  Future<AuthResult> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error(message: "No user logged in");
      }

      if (name != null) {
        await user.updateDisplayName(name);
      }

      if (email != null) {
        await user.updateEmail(email);
      }

      // Update local user data
      final currentUserData = await _getUserData(user.uid);
      if (currentUserData != null) {
        final updatedUser = currentUserData.copyWith(
          name: name ?? currentUserData.name,
          email: email ?? currentUserData.email,
        );
        await _saveUserData(updatedUser);
      }

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult.error(message: "Failed to update profile");
    }
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData);
        return User.fromJson(userJson);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Auto-login on app launch
  Future<bool> autoLogin() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Get user data from storage
        final user = await getStoredUser();
        if (user != null) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Auto-login error: $e');
      return false;
    }
  }

  // Get user data from storage
  Future<User?> _getUserData(String uid) async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        final userJson = jsonDecode(userData);
        final user = User.fromJson(userJson);
        // Verify the user ID matches
        if (user.id == uid) {
          return user;
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Save user data to storage
  Future<void> _saveUserData(User user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Get Firebase error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Get Firebase ID token for backend authentication
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      print('Error getting ID token: $e');
    }
    return null;
  }

  // Verify if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Verify the token is still valid
        await user.getIdToken(true); // Force refresh
        return true;
      }
    } catch (e) {
      print('Authentication verification failed: $e');
    }
    return false;
  }
}

// Auth result class
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
