# Civic Sense - Complete Setup Guide

This guide will help you set up the complete authentication flow with Gemini AI integration for your Civic Sense app.

## 🎯 What You Need to Provide

### 1. **PostgreSQL Database Setup**
You need to install and configure PostgreSQL on your system:

**For Windows:**
- Download PostgreSQL from https://www.postgresql.org/download/windows/
- Install with default settings
- Remember the password you set for the `postgres` user

**For macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**For Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. **Python Environment**
You need Python 3.8+ installed on your system.

### 3. **Database Credentials**
You'll need to provide:
- Database username (usually `postgres`)
- Database password (the one you set during installation)
- Database name (we'll use `civic_sense`)

## 🚀 Step-by-Step Setup

### Step 1: Create PostgreSQL Database

1. **Connect to PostgreSQL:**
```bash
# Windows (use Command Prompt as Administrator)
psql -U postgres

# macOS/Linux
sudo -u postgres psql
```

2. **Create Database and User:**
```sql
-- Create database
CREATE DATABASE civic_sense;

-- Create user (optional, you can use postgres user)
CREATE USER civic_user WITH PASSWORD 'your_password_here';
GRANT ALL PRIVILEGES ON DATABASE civic_sense TO civic_user;

-- Exit psql
\q
```

### Step 2: Set Up Backend Environment

1. **Navigate to your project directory:**
```bash
cd citizen_app
```

2. **Create virtual environment:**
```bash
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
```

3. **Install dependencies:**
```bash
pip install -r requirements.txt
```

4. **Create environment file:**
Create a `.env` file in the `citizen_app` directory with your actual credentials:

```env
# Database Configuration
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/civic_sense

# JWT Configuration
JWT_SECRET_KEY=your-super-secret-jwt-key-here-make-it-long-and-random

# Gemini API Configuration
GEMINI_API_KEY=AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI

# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-flask-secret-key-here-also-make-it-random

# Server Configuration
HOST=0.0.0.0
PORT=5000
```

**⚠️ IMPORTANT:** Replace `YOUR_PASSWORD` with your actual PostgreSQL password!

### Step 3: Update Backend Code

The `backend_example.py` file needs a small update to use environment variables. Here's the updated version:

```python
# Add this at the top of backend_example.py
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Update the configuration section
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost/civic_sense')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'fallback-jwt-secret')

# Update Gemini configuration
genai.configure(api_key=os.getenv('GEMINI_API_KEY', 'AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI'))
```

### Step 4: Initialize Database

1. **Run the backend to create tables:**
```bash
python backend_example.py
```

2. **The first run will create all necessary tables automatically.**

3. **Stop the server (Ctrl+C) and restart it:**
```bash
python backend_example.py
```

### Step 5: Test Backend API

1. **Test if server is running:**
Open your browser and go to: `http://localhost:5000/api/auth/signup`

You should see a method not allowed error (this is expected for GET request).

2. **Test with Postman or curl:**
```bash
# Test signup
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "role": "citizen"
  }'
```

### Step 6: Update Flutter App

1. **Install Flutter dependencies:**
```bash
cd citizen_app
flutter pub get
```

2. **Update the base URL in your Flutter app:**
In `lib/config/app_config.dart`, make sure the base URL is correct:
```dart
static const String baseUrl = "http://10.0.2.2:5000/api"; // For Android emulator
// For iOS simulator, use: "http://localhost:5000/api"
// For physical device, use your computer's IP address
```

### Step 7: Test Complete Flow

1. **Run Flutter app:**
```bash
flutter run
```

2. **Test the authentication flow:**
   - Try signing up with a new account
   - Try logging in
   - Check if auto-login works on app restart

## 🔧 Troubleshooting

### Common Issues:

1. **Database Connection Error:**
   - Check if PostgreSQL is running
   - Verify your password in the `.env` file
   - Make sure the database `civic_sense` exists

2. **Port Already in Use:**
   - Change the port in `.env` file
   - Or kill the process using port 5000

3. **Flutter Can't Connect to Backend:**
   - For Android emulator: Use `10.0.2.2:5000`
   - For iOS simulator: Use `localhost:5000`
   - For physical device: Use your computer's IP address

4. **Gemini API Errors:**
   - Verify your API key is correct
   - Check if you have quota remaining
   - Ensure internet connection

## 📋 Checklist

- [ ] PostgreSQL installed and running
- [ ] Database `civic_sense` created
- [ ] Python virtual environment created and activated
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] `.env` file created with correct credentials
- [ ] Backend server running on port 5000
- [ ] Database tables created (check with first run)
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Flutter app can connect to backend
- [ ] Signup/login flow working
- [ ] Auto-login working
- [ ] Gemini AI integration working

## 🎉 What You'll Have

After completing this setup, you'll have:

1. **Complete Authentication System:**
   - User registration with role selection
   - Secure login with JWT tokens
   - Auto-login on app launch
   - Role-based access control (citizen, staff, admin)

2. **Gemini AI Integration:**
   - Automatic complaint classification
   - Sentiment analysis
   - Summary generation
   - Suggested actions

3. **Secure Data Storage:**
   - Passwords hashed with bcrypt
   - JWT tokens for authentication
   - Secure token storage in Flutter
   - PostgreSQL database with proper relationships

4. **Role-Based Features:**
   - Citizens can create and track complaints
   - Staff can manage complaint status
   - Admins can view analytics and manage users

## 🆘 Need Help?

If you encounter any issues:

1. Check the console output for error messages
2. Verify all environment variables are set correctly
3. Ensure PostgreSQL is running and accessible
4. Check if the backend server is running on the correct port
5. Verify your Gemini API key is valid and has quota

The system is designed to be robust and handle errors gracefully, but proper setup is crucial for everything to work smoothly.
