# CivicSense - Complete Implementation Guide

This guide provides step-by-step instructions to implement the complete CivicSense application with Firebase Authentication, Gemini AI integration, and PostgreSQL backend.

## 🏗️ Architecture Overview

```
Flutter App (Mobile) 
    ↓ Firebase Auth
    ↓ API Calls
FastAPI Backend (Python)
    ↓ Firebase Admin SDK
    ↓ Database Operations
PostgreSQL Database
    ↓ AI Processing
Gemini AI (Google)
    ↓ Media Storage
Firebase Storage
```

## 📋 Prerequisites

### 1. Development Environment
- Flutter SDK (3.0+)
- Python 3.8+
- PostgreSQL 12+
- Node.js (for Firebase CLI)
- Git

### 2. Accounts & Services
- Google Cloud Platform account
- Firebase project
- Gemini API access
- PostgreSQL database (local or cloud)

## 🚀 Step 1: Firebase Project Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Project name: `civic-sense`
4. Enable Google Analytics (optional)
5. Create project

### 1.2 Enable Authentication
1. Go to Authentication → Get started
2. Sign-in method → Add provider
3. Enable "Email/Password"
4. Enable "Google" (optional)

### 1.3 Enable Storage
1. Go to Storage → Get started
2. Start in test mode
3. Choose location (closest to your users)

### 1.4 Download Configuration Files
1. Project Settings → General
2. Add app → Flutter
3. Download `google-services.json` (Android)
4. Download `GoogleService-Info.plist` (iOS)

## 🗄️ Step 2: Database Setup

### 2.1 Install PostgreSQL
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# macOS
brew install postgresql
brew services start postgresql

# Windows
# Download from https://www.postgresql.org/download/windows/
```

### 2.2 Create Database
```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE civic_sense;
CREATE USER civic_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE civic_sense TO civic_user;
\q
```

### 2.3 Run Schema
```bash
# Navigate to backend directory
cd citizen_app/backend

# Run the schema
psql -U civic_user -d civic_sense -f schema.sql
```

## 🔧 Step 3: Backend Setup

### 3.1 Create Virtual Environment
```bash
cd citizen_app/backend
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
```

### 3.2 Install Dependencies
```bash
pip install -r requirements.txt
```

### 3.3 Configure Environment
```bash
# Copy environment template
cp env_example.txt .env

# Edit .env with your actual values
DATABASE_URL=postgresql://civic_user:your_password@localhost:5432/civic_sense
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### 3.4 Get Firebase Service Account Key
1. Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Save as `firebase-service-account.json` in backend directory

### 3.5 Start Backend Server
```bash
python main.py
```

Server should start on `http://localhost:8000`

## 📱 Step 4: Flutter App Setup

### 4.1 Install Dependencies
```bash
cd citizen_app
flutter pub get
```

### 4.2 Configure Firebase
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure FlutterFire
flutterfire configure
```

### 4.3 Add Configuration Files
1. Copy `google-services.json` to `android/app/`
2. Copy `GoogleService-Info.plist` to `ios/Runner/`

### 4.4 Update Android Configuration
Edit `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

Edit `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 4.5 Generate Model Files
```bash
flutter packages pub run build_runner build
```

## 🧪 Step 5: Testing Setup

### 5.1 Test Backend
```bash
cd citizen_app/backend
python test_setup.py
```

### 5.2 Test Flutter App
```bash
cd citizen_app
flutter run
```

## 📁 Project Structure

```
citizen_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   └── complaint.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── gemini_service.dart
│   │   ├── storage_service.dart
│   │   └── location_service.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── citizen/
│   │   ├── staff/
│   │   └── admin/
│   └── widgets/
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── schema.sql
│   └── .env
└── android/
    └── app/
        └── google-services.json
```

## 🔑 Key Configuration Files

### Environment Variables (.env)
```env
DATABASE_URL=postgresql://civic_user:password@localhost:5432/civic_sense
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
GEMINI_API_KEY=AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI
```

### App Configuration (lib/config/app_config.dart)
```dart
class AppConfig {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Android emulator
  static const String geminiApiKey = "AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI";
  // ... other config
}
```

## 🚦 Development Workflow

### 1. Start Backend
```bash
cd citizen_app/backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
python main.py
```

### 2. Start Flutter App
```bash
cd citizen_app
flutter run
```

### 3. Test End-to-End Flow
1. Sign up with email/password
2. Submit a complaint with image
3. Check database for new record
4. Test staff login and status update

## 🔒 Security Checklist

- [ ] Firebase service account key is secure
- [ ] Database credentials are in .env (not committed)
- [ ] API endpoints require authentication
- [ ] Input validation on all forms
- [ ] File upload size limits
- [ ] HTTPS in production

## 🐛 Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Check `google-services.json` is in correct location
   - Verify Firebase project configuration

2. **Database connection failed**
   - Check PostgreSQL is running
   - Verify credentials in .env file
   - Test connection: `psql -U civic_user -d civic_sense`

3. **Gemini API errors**
   - Verify API key is correct
   - Check API quota limits
   - Test with simple request

4. **Flutter build errors**
   - Run `flutter clean && flutter pub get`
   - Check for missing dependencies
   - Verify Firebase configuration

### Debug Commands

```bash
# Check backend health
curl http://localhost:8000/health

# Test database connection
psql -U civic_user -d civic_sense -c "SELECT * FROM users LIMIT 1;"

# Check Flutter dependencies
flutter doctor

# View backend logs
tail -f backend/logs/app.log
```

## 📊 Monitoring & Analytics

### Backend Monitoring
- Health check endpoint: `/health`
- Database connection status
- API response times

### Flutter Analytics
- Firebase Analytics (automatic)
- Crashlytics for error tracking
- Performance monitoring

## 🚀 Production Deployment

### Backend Deployment
1. Use production PostgreSQL (AWS RDS, Google Cloud SQL)
2. Deploy FastAPI to cloud (Heroku, AWS, Google Cloud)
3. Set up environment variables
4. Configure CORS for production domains

### Flutter App Deployment
1. Build release APK/IPA
2. Upload to app stores
3. Configure production Firebase project
4. Set up push notifications

## 📈 Next Steps

1. **Implement remaining screens** (complaint form, staff dashboard)
2. **Add push notifications** (Firebase Cloud Messaging)
3. **Implement offline support** (local storage, sync)
4. **Add analytics dashboard** (admin features)
5. **Performance optimization** (caching, lazy loading)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review Firebase console for errors
3. Check backend logs
4. Verify all configuration files
5. Test individual components

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Gemini API Documentation](https://ai.google.dev/docs)

This setup provides a solid foundation for the CivicSense application with all the core components working together securely and efficiently.
