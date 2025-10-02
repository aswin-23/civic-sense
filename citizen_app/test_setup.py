#!/usr/bin/env python3
"""
Test script to verify Civic Sense backend setup
Run this after setting up your environment to test if everything is working
"""

import requests
import json
import sys

BASE_URL = "http://localhost:5000/api"

def test_server_connection():
    """Test if the server is running"""
    try:
        response = requests.get(f"{BASE_URL}/auth/signup", timeout=5)
        print("✅ Server is running and accessible")
        return True
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Make sure backend is running on port 5000")
        return False
    except Exception as e:
        print(f"✅ Server is running (got expected error: {e})")
        return True

def test_signup():
    """Test user signup"""
    try:
        data = {
            "name": "Test User",
            "email": "test@example.com",
            "password": "password123",
            "role": "citizen"
        }
        
        response = requests.post(
            f"{BASE_URL}/auth/signup",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            result = response.json()
            print("✅ User signup successful")
            return result.get('token'), result.get('user')
        else:
            print(f"❌ Signup failed: {response.status_code} - {response.text}")
            return None, None
            
    except Exception as e:
        print(f"❌ Signup test failed: {e}")
        return None, None

def test_login():
    """Test user login"""
    try:
        data = {
            "email": "test@example.com",
            "password": "password123"
        }
        
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ User login successful")
            return result.get('token'), result.get('user')
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            return None, None
            
    except Exception as e:
        print(f"❌ Login test failed: {e}")
        return None, None

def test_gemini_classification(token):
    """Test Gemini AI classification"""
    try:
        data = {
            "text": "There's a large pothole on Main Street that's been there for weeks and is causing damage to cars",
            "location": "Main Street, Downtown",
            "category": "infrastructure"
        }
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
        
        response = requests.post(
            f"{BASE_URL}/gemini/classify",
            json=data,
            headers=headers
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Gemini AI classification working")
            print(f"   Category: {result.get('classification', {}).get('category', 'N/A')}")
            print(f"   Priority: {result.get('classification', {}).get('priority', 'N/A')}")
            return True
        else:
            print(f"❌ Gemini classification failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Gemini test failed: {e}")
        return False

def test_complaint_creation(token):
    """Test complaint creation with Gemini integration"""
    try:
        data = {
            "title": "Test Pothole Complaint",
            "description": "There's a large pothole on Main Street that's been there for weeks and is causing damage to cars. It's getting worse every day.",
            "location": "Main Street, Downtown",
            "category": "infrastructure",
            "priority": "medium"
        }
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
        
        response = requests.post(
            f"{BASE_URL}/complaints",
            json=data,
            headers=headers
        )
        
        if response.status_code == 201:
            result = response.json()
            print("✅ Complaint creation successful")
            print(f"   Complaint ID: {result.get('complaint', {}).get('id', 'N/A')}")
            print(f"   Gemini Classification: {result.get('complaint', {}).get('gemini_classification', 'N/A')}")
            return True
        else:
            print(f"❌ Complaint creation failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Complaint creation test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing Civic Sense Backend Setup")
    print("=" * 50)
    
    # Test 1: Server connection
    if not test_server_connection():
        print("\n❌ Setup incomplete. Please check your backend server.")
        sys.exit(1)
    
    print()
    
    # Test 2: User signup
    token, user = test_signup()
    if not token:
        print("\n❌ Signup failed. Check your database connection and setup.")
        sys.exit(1)
    
    print()
    
    # Test 3: User login
    login_token, login_user = test_login()
    if not login_token:
        print("\n❌ Login failed. Check your authentication setup.")
        sys.exit(1)
    
    print()
    
    # Test 4: Gemini AI classification
    if not test_gemini_classification(token):
        print("\n❌ Gemini AI integration failed. Check your API key and internet connection.")
        sys.exit(1)
    
    print()
    
    # Test 5: Complaint creation
    if not test_complaint_creation(token):
        print("\n❌ Complaint creation failed. Check your database and Gemini integration.")
        sys.exit(1)
    
    print()
    print("🎉 All tests passed! Your Civic Sense backend is working correctly.")
    print("\nNext steps:")
    print("1. Run your Flutter app: flutter run")
    print("2. Test the complete authentication flow")
    print("3. Try creating complaints and see Gemini AI in action!")

if __name__ == "__main__":
    main()
