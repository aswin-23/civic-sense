# Firebase Authentication Setup Guide for Civic Sense

This guide will help you integrate Google Firebase Authentication with your Civic Sense app, providing a more robust and scalable authentication solution.

## 🎯 What You Need to Provide

### 1. **Google Account**
- A Google account to access Firebase Console
- Access to create Firebase projects

### 2. **Firebase Project Configuration**
- Project name: "Civic Sense" (or your preferred name)
- Enable Authentication with Email/Password and Google Sign-In

## 🚀 Step-by-Step Firebase Setup

### Step 1: Create Firebase Project

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Sign in with your Google account

2. **Create New Project:**
   - Click "Create a project"
   - Project name: `civic-sense` (or your preferred name)
   - Enable Google Analytics (optional but recommended)
   - Choose or create a Google Analytics account
   - Click "Create project"

3. **Wait for project creation to complete**

### Step 2: Add Flutter App to Firebase Project

1. **Add App:**
   - Click "Add app" and select the Flutter icon
   - Register app nickname: `Civic Sense Flutter`
   - Click "Register app"

2. **Download Configuration Files:**
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - **Keep these files secure - they contain sensitive information**

### Step 3: Configure Authentication

1. **Enable Authentication:**
   - In Firebase Console, go to "Authentication" → "Get started"
   - Go to "Sign-in method" tab
   - Enable "Email/Password" provider
   - Enable "Google" provider (optional for social login)

2. **Configure Email/Password:**
   - Click on "Email/Password"
   - Enable "Email/Password" (first option)
   - Click "Save"

3. **Configure Google Sign-In (Optional):**
   - Click on "Google"
   - Enable Google sign-in
   - Set project support email
   - Click "Save"

### Step 4: Set Up Flutter Dependencies

1. **Update pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase dependencies
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
  
  # Existing dependencies
  http: ^0.13.6
  flutter_secure_storage: ^9.0.0
  geolocator: ^9.0.2
  image_picker: ^1.0.7
  postgres: ^2.6.3
  provider: ^6.1.5
  jwt_decoder: ^2.0.1
  crypto: ^3.0.3
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.8
```

2. **Install dependencies:**
```bash
flutter pub get
```

### Step 5: Configure Android

1. **Add google-services.json:**
   - Copy `google-services.json` to `android/app/` directory
   - Make sure it's in the correct location: `android/app/google-services.json`

2. **Update android/build.gradle:**
   - Open `android/build.gradle` (project level)
   - Add to dependencies:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

3. **Update android/app/build.gradle:**
   - Open `android/app/build.gradle`
   - Add at the top:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 6: Configure iOS

1. **Add GoogleService-Info.plist:**
   - Copy `GoogleService-Info.plist` to `ios/Runner/` directory
   - Make sure it's in the correct location: `ios/Runner/GoogleService-Info.plist`

2. **Update ios/Runner/Info.plist:**
   - Add URL schemes for Google Sign-In:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```
   - Replace `YOUR_REVERSED_CLIENT_ID` with the value from `GoogleService-Info.plist`

### Step 7: Initialize Firebase in Flutter

1. **Update main.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This will be generated
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_services.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civic Sense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        "/login": (context) => const LoginScreen(),
        "/signup": (context) => const SignupScreen(),
        "/home": (context) => const HomeScreen(),
        "/staff-dashboard": (context) => const StaffDashboard(),
        "/admin-dashboard": (context) => const AdminDashboard(),
      },
    );
  }
}

// Rest of your existing code...
```

2. **Generate Firebase options:**
```bash
flutterfire configure
```
   - This will create `lib/firebase_options.dart` with your project configuration

### Step 8: Create Firebase Authentication Service

Create a new file `lib/services/firebase_auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

        return AuthResult.success(user: customUser);
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
      await _storage.delete(key: 'user_data');
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

  // Get user data from storage
  Future<User?> _getUserData(String uid) async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        final userJson = jsonDecode(userData);
        return User.fromJson(userJson);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Save user data to storage
  Future<void> _saveUserData(User user) async {
    try {
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
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
      default:
        return 'An error occurred: ${e.message}';
    }
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
```

### Step 9: Update Your Existing Auth Service

You can either:
1. **Replace** your existing auth service with Firebase
2. **Hybrid approach** - use Firebase for authentication and your backend for user management

For the hybrid approach, update your existing `auth_services.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'firebase_auth_service.dart';

class AuthService {
  final String baseUrl = AppConfig.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  
  // Use Firebase for authentication, backend for user management
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
  }) async {
    // First, create user in Firebase
    final firebaseResult = await _firebaseAuth.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    if (firebaseResult.isSuccess && firebaseResult.user != null) {
      // Then, create user in your backend
      try {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse("$baseUrl/auth/firebase-signup"),
          headers: headers,
          body: jsonEncode({
            "firebase_uid": firebaseResult.user!.id,
            "name": name,
            "email": email,
            "role": role.value,
          }),
        );

        if (response.statusCode == 201) {
          return AuthResult.success(user: firebaseResult.user);
        }
      } catch (e) {
        // If backend fails, still return success since Firebase user was created
        return AuthResult.success(user: firebaseResult.user);
      }
    }

    return firebaseResult;
  }

  // Similar updates for login, logout, etc.
  // Use Firebase for authentication, sync with backend for user data
}
```

### Step 10: Update Backend to Support Firebase

Add Firebase Admin SDK to your backend:

1. **Install Firebase Admin SDK:**
```bash
pip install firebase-admin
```

2. **Update backend_example.py:**
```python
import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase Admin SDK
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Add Firebase user verification endpoint
@app.route('/api/auth/firebase-signup', methods=['POST'])
@jwt_required()
def firebase_signup():
    data = request.get_json()
    firebase_uid = data.get('firebase_uid')
    
    # Verify Firebase token
    try:
        decoded_token = auth.verify_id_token(firebase_uid)
        uid = decoded_token['uid']
        
        # Create user in your database
        user = User(
            id=uid,
            name=data['name'],
            email=data['email'],
            role=data['role'],
            firebase_uid=uid
        )
        
        db.session.add(user)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'User created successfully',
            'user': user.to_dict()
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Firebase verification failed: {str(e)}'
        }), 400
```

## 🧪 Testing Firebase Authentication

1. **Test Email/Password Signup:**
```bash
# Run your Flutter app
flutter run

# Try creating an account with email/password
```

2. **Test Google Sign-In:**
```bash
# Make sure Google Sign-In is configured
# Test the Google sign-in button
```

3. **Test Password Reset:**
```bash
# Test the "Forgot Password" functionality
```

## 🔧 Troubleshooting

### Common Issues:

1. **Firebase not initialized:**
   - Make sure `Firebase.initializeApp()` is called in main()
   - Check that `firebase_options.dart` is generated correctly

2. **Google Sign-In not working:**
   - Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
   - Check SHA-1 fingerprints in Firebase Console
   - Ensure URL schemes are configured for iOS

3. **Authentication errors:**
   - Check Firebase Console for error logs
   - Verify authentication methods are enabled
   - Check network connectivity

## 🎉 Benefits of Firebase Authentication

1. **Security:**
   - Google's robust security infrastructure
   - Automatic security updates
   - Built-in protection against common attacks

2. **Scalability:**
   - Handles millions of users
   - Global CDN for fast authentication
   - Automatic scaling

3. **Features:**
   - Multiple sign-in methods
   - Password reset
   - Email verification
   - User management
   - Analytics and monitoring

4. **Integration:**
   - Easy integration with other Firebase services
   - Works seamlessly with Flutter
   - Cross-platform support

This setup provides a production-ready authentication system that's more secure and scalable than a custom JWT implementation!
