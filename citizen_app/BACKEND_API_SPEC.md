# Backend API Specification for Civic Sense

This document outlines the backend API endpoints that need to be implemented to support the Flutter authentication flow with Gemini AI integration.

## Base URL
```
http://10.0.2.2:5000/api
```

## Authentication Flow

### 1. User Registration
**POST** `/auth/signup`

Request Body:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "citizen"
}
```

Response (201):
```json
{
  "success": true,
  "message": "User created successfully",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "citizen",
    "created_at": "2024-01-01T00:00:00Z",
    "is_active": true
  },
  "token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token"
}
```

### 2. User Login
**POST** `/auth/login`

Request Body:
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "citizen",
    "created_at": "2024-01-01T00:00:00Z",
    "last_login_at": "2024-01-01T12:00:00Z",
    "is_active": true
  },
  "token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token"
}
```

### 3. Token Refresh
**POST** `/auth/refresh`

Request Body:
```json
{
  "refresh_token": "jwt_refresh_token"
}
```

Response (200):
```json
{
  "success": true,
  "token": "new_jwt_access_token",
  "refresh_token": "new_jwt_refresh_token"
}
```

### 4. Logout
**POST** `/auth/logout`

Headers:
```
Authorization: Bearer <jwt_access_token>
```

Response (200):
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

## Gemini AI Integration

### 1. Classify Complaint
**POST** `/gemini/classify`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "text": "There's a pothole on Main Street that's been there for weeks",
  "location": "Main Street, Downtown",
  "category": "infrastructure"
}
```

Response (200):
```json
{
  "success": true,
  "classification": {
    "category": "Infrastructure",
    "priority": "medium",
    "confidence": 0.85,
    "keywords": ["pothole", "road", "infrastructure"],
    "suggested_department": "Public Works"
  }
}
```

### 2. Generate Summary
**POST** `/gemini/summarize`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "text": "Long complaint description...",
  "location": "Location",
  "category": "Category"
}
```

Response (200):
```json
{
  "success": true,
  "summary": "Brief summary of the complaint"
}
```

### 3. Get Suggested Actions
**POST** `/gemini/suggest-actions`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "text": "Complaint text",
  "category": "Category",
  "priority": "Priority"
}
```

Response (200):
```json
{
  "success": true,
  "actions": [
    "Inspect the location within 24 hours",
    "Contact the responsible department",
    "Schedule repair work"
  ]
}
```

### 4. Analyze Sentiment
**POST** `/gemini/sentiment`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "text": "Complaint text"
}
```

Response (200):
```json
{
  "success": true,
  "sentiment": {
    "sentiment": "negative",
    "score": -0.7,
    "description": "The complaint expresses frustration and urgency"
  }
}
```

### 5. Get Analytics (Admin Only)
**POST** `/gemini/analytics`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-01-31T23:59:59Z",
  "category": "infrastructure",
  "location": "downtown"
}
```

Response (200):
```json
{
  "success": true,
  "analytics": {
    "total_complaints": 150,
    "complaints_by_category": {
      "infrastructure": 45,
      "environment": 30,
      "safety": 25
    },
    "complaints_by_priority": {
      "high": 20,
      "medium": 80,
      "low": 50
    },
    "complaints_by_status": {
      "pending": 30,
      "in_progress": 40,
      "resolved": 60,
      "closed": 20
    },
    "trends": [
      {
        "date": "2024-01-01",
        "count": 5,
        "category": "infrastructure"
      }
    ],
    "insights": "Infrastructure complaints have increased by 20% this month"
  }
}
```

## Complaint Management

### 1. Create Complaint
**POST** `/complaints`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "title": "Pothole on Main Street",
  "description": "There's a large pothole...",
  "location": "Main Street, Downtown",
  "category": "infrastructure",
  "priority": "medium",
  "image_urls": ["url1", "url2"],
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

Response (201):
```json
{
  "success": true,
  "message": "Complaint created successfully",
  "complaint": {
    "id": "complaint_id",
    "title": "Pothole on Main Street",
    "description": "There's a large pothole...",
    "location": "Main Street, Downtown",
    "category": "infrastructure",
    "priority": "medium",
    "status": "pending",
    "user_id": "user_id",
    "user_name": "John Doe",
    "image_urls": ["url1", "url2"],
    "latitude": 40.7128,
    "longitude": -74.0060,
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z",
    "gemini_classification": "Infrastructure",
    "gemini_summary": "Brief summary",
    "gemini_keywords": ["pothole", "road"]
  }
}
```

### 2. Get User Complaints
**GET** `/complaints/my?page=1&limit=20&status=pending&category=infrastructure`

Headers:
```
Authorization: Bearer <jwt_access_token>
```

Response (200):
```json
{
  "success": true,
  "complaints": [
    {
      "id": "complaint_id",
      "title": "Pothole on Main Street",
      "status": "pending",
      "priority": "medium",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

### 3. Get All Complaints (Staff/Admin)
**GET** `/complaints?page=1&limit=20&status=pending&category=infrastructure&priority=high&assigned_to=staff_id`

Headers:
```
Authorization: Bearer <jwt_access_token>
```

Response (200):
```json
{
  "success": true,
  "complaints": [
    {
      "id": "complaint_id",
      "title": "Pothole on Main Street",
      "status": "pending",
      "priority": "high",
      "assigned_to": "staff_id",
      "assigned_to_name": "Jane Smith",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

### 4. Update Complaint Status (Staff/Admin)
**PUT** `/complaints/{complaint_id}/status`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "status": "in_progress",
  "notes": "Work crew dispatched",
  "assigned_to": "staff_id"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Complaint status updated",
  "complaint": {
    "id": "complaint_id",
    "status": "in_progress",
    "notes": "Work crew dispatched",
    "assigned_to": "staff_id",
    "assigned_to_name": "Jane Smith",
    "updated_at": "2024-01-01T13:00:00Z"
  }
}
```

## User Management (Admin Only)

### 1. Get Users
**GET** `/users?page=1&limit=20&role=staff&is_active=true`

Headers:
```
Authorization: Bearer <jwt_access_token>
```

Response (200):
```json
{
  "success": true,
  "users": [
    {
      "id": "user_id",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "role": "staff",
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "last_login_at": "2024-01-01T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

### 2. Update User Status
**PUT** `/users/{user_id}/status`

Headers:
```
Authorization: Bearer <jwt_access_token>
Content-Type: application/json
```

Request Body:
```json
{
  "is_active": false
}
```

Response (200):
```json
{
  "success": true,
  "message": "User status updated",
  "user": {
    "id": "user_id",
    "is_active": false,
    "updated_at": "2024-01-01T13:00:00Z"
  }
}
```

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "error_code": "ERROR_CODE"
}
```

Common HTTP status codes:
- `400` - Bad Request
- `401` - Unauthorized (invalid/expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

## Gemini API Integration

The backend should integrate with Google's Gemini API using the provided API key:

```python
# Example Python backend integration
import google.generativeai as genai

# Configure Gemini API
genai.configure(api_key="AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI")

# Initialize the model
model = genai.GenerativeModel('gemini-pro')

# Example classification function
def classify_complaint(text, location=None, category=None):
    prompt = f"""
    Analyze this complaint and provide classification:
    
    Text: {text}
    Location: {location or 'Not specified'}
    Category: {category or 'Not specified'}
    
    Please provide:
    1. Category (infrastructure, environment, safety, etc.)
    2. Priority (low, medium, high, urgent)
    3. Confidence score (0-1)
    4. Keywords (list of important terms)
    5. Suggested department
    
    Return as JSON format.
    """
    
    response = model.generate_content(prompt)
    return response.text
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('citizen', 'staff', 'admin')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Complaints Table
```sql
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed', 'rejected')),
    user_id UUID REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    image_urls TEXT[],
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    notes TEXT,
    gemini_classification VARCHAR(100),
    gemini_summary TEXT,
    gemini_keywords TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);
```

### Comments Table
```sql
CREATE TABLE complaint_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    comment TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

This specification provides a complete backend API that integrates with your Gemini API key and supports the full authentication flow with role-based access control.
