"""
Backend API Example for Civic Sense
This is a sample implementation showing how to integrate Gemini AI with authentication
"""

from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from datetime import datetime, timedelta
import google.generativeai as genai
import os
import uuid
from functools import wraps
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret-key-change-this')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost/civic_sense')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'fallback-jwt-secret-change-this')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=7)

# Initialize extensions
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

# Configure Gemini AI
genai.configure(api_key=os.getenv('GEMINI_API_KEY', 'AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI'))
model = genai.GenerativeModel('gemini-pro')

# Database Models
class User(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False, default='citizen')
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login_at = db.Column(db.DateTime)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'role': self.role,
            'created_at': self.created_at.isoformat(),
            'last_login_at': self.last_login_at.isoformat() if self.last_login_at else None,
            'is_active': self.is_active
        }

class Complaint(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    location = db.Column(db.String(255), nullable=False)
    category = db.Column(db.String(50))
    priority = db.Column(db.String(20), nullable=False, default='medium')
    status = db.Column(db.String(20), nullable=False, default='pending')
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    assigned_to = db.Column(db.String(36), db.ForeignKey('user.id'))
    image_urls = db.Column(db.JSON)
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    notes = db.Column(db.Text)
    gemini_classification = db.Column(db.String(100))
    gemini_summary = db.Column(db.Text)
    gemini_keywords = db.Column(db.JSON)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = db.Column(db.DateTime)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'location': self.location,
            'category': self.category,
            'priority': self.priority,
            'status': self.status,
            'user_id': self.user_id,
            'assigned_to': self.assigned_to,
            'image_urls': self.image_urls or [],
            'latitude': self.latitude,
            'longitude': self.longitude,
            'notes': self.notes,
            'gemini_classification': self.gemini_classification,
            'gemini_summary': self.gemini_summary,
            'gemini_keywords': self.gemini_keywords or [],
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'resolved_at': self.resolved_at.isoformat() if self.resolved_at else None
        }

# Role-based access control decorator
def require_role(roles):
    def decorator(f):
        @wraps(f)
        @jwt_required()
        def decorated_function(*args, **kwargs):
            current_user_id = get_jwt_identity()
            user = User.query.get(current_user_id)
            if not user or user.role not in roles:
                return jsonify({'success': False, 'message': 'Access denied'}), 403
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Gemini AI Functions
def classify_complaint_with_gemini(text, location=None, category=None):
    """Use Gemini AI to classify complaint"""
    try:
        prompt = f"""
        Analyze this complaint and provide classification in JSON format:
        
        Complaint Text: {text}
        Location: {location or 'Not specified'}
        Category: {category or 'Not specified'}
        
        Please provide:
        1. category: (infrastructure, environment, safety, health, transportation, utilities, other)
        2. priority: (low, medium, high, urgent)
        3. confidence: (0.0 to 1.0)
        4. keywords: (array of important terms)
        5. suggested_department: (appropriate department name)
        
        Return only valid JSON, no additional text.
        """
        
        response = model.generate_content(prompt)
        # Parse the JSON response
        import json
        result = json.loads(response.text.strip())
        return result
    except Exception as e:
        print(f"Gemini classification error: {e}")
        return {
            'category': 'other',
            'priority': 'medium',
            'confidence': 0.5,
            'keywords': [],
            'suggested_department': 'General'
        }

def generate_summary_with_gemini(text, location=None, category=None):
    """Use Gemini AI to generate complaint summary"""
    try:
        prompt = f"""
        Generate a concise summary (max 100 words) for this complaint:
        
        Text: {text}
        Location: {location or 'Not specified'}
        Category: {category or 'Not specified'}
        
        Focus on the main issue and key details.
        """
        
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        print(f"Gemini summary error: {e}")
        return "Summary generation failed"

def analyze_sentiment_with_gemini(text):
    """Use Gemini AI to analyze sentiment"""
    try:
        prompt = f"""
        Analyze the sentiment of this complaint text and return JSON:
        
        Text: {text}
        
        Provide:
        1. sentiment: (positive, negative, neutral)
        2. score: (-1.0 to 1.0, where -1 is very negative, 1 is very positive)
        3. description: (brief explanation of the sentiment)
        
        Return only valid JSON.
        """
        
        response = model.generate_content(prompt)
        import json
        result = json.loads(response.text.strip())
        return result
    except Exception as e:
        print(f"Gemini sentiment error: {e}")
        return {
            'sentiment': 'neutral',
            'score': 0.0,
            'description': 'Sentiment analysis failed'
        }

# Authentication Routes
@app.route('/api/auth/signup', methods=['POST'])
def signup():
    data = request.get_json()
    
    # Validate input
    if not all(k in data for k in ('name', 'email', 'password')):
        return jsonify({'success': False, 'message': 'Missing required fields'}), 400
    
    # Check if user exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'success': False, 'message': 'Email already registered'}), 400
    
    # Create user
    user = User(
        id=str(uuid.uuid4()),
        name=data['name'],
        email=data['email'],
        password_hash=bcrypt.generate_password_hash(data['password']).decode('utf-8'),
        role=data.get('role', 'citizen')
    )
    
    db.session.add(user)
    db.session.commit()
    
    # Generate tokens
    access_token = create_access_token(identity=user.id)
    refresh_token = create_refresh_token(identity=user.id)
    
    return jsonify({
        'success': True,
        'message': 'User created successfully',
        'user': user.to_dict(),
        'token': access_token,
        'refresh_token': refresh_token
    }), 201

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # Validate input
    if not all(k in data for k in ('email', 'password')):
        return jsonify({'success': False, 'message': 'Missing email or password'}), 400
    
    # Find user
    user = User.query.filter_by(email=data['email']).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, data['password']):
        return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
    
    if not user.is_active:
        return jsonify({'success': False, 'message': 'Account is deactivated'}), 401
    
    # Update last login
    user.last_login_at = datetime.utcnow()
    db.session.commit()
    
    # Generate tokens
    access_token = create_access_token(identity=user.id)
    refresh_token = create_refresh_token(identity=user.id)
    
    return jsonify({
        'success': True,
        'message': 'Login successful',
        'user': user.to_dict(),
        'token': access_token,
        'refresh_token': refresh_token
    })

@app.route('/api/auth/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user or not user.is_active:
        return jsonify({'success': False, 'message': 'Invalid user'}), 401
    
    new_token = create_access_token(identity=current_user_id)
    new_refresh_token = create_refresh_token(identity=current_user_id)
    
    return jsonify({
        'success': True,
        'token': new_token,
        'refresh_token': new_refresh_token
    })

@app.route('/api/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    # In a real implementation, you might want to blacklist the token
    return jsonify({'success': True, 'message': 'Logged out successfully'})

# Gemini AI Routes
@app.route('/api/gemini/classify', methods=['POST'])
@jwt_required()
def classify_complaint():
    data = request.get_json()
    
    if not data.get('text'):
        return jsonify({'success': False, 'message': 'Text is required'}), 400
    
    classification = classify_complaint_with_gemini(
        data['text'],
        data.get('location'),
        data.get('category')
    )
    
    return jsonify({
        'success': True,
        'classification': classification
    })

@app.route('/api/gemini/summarize', methods=['POST'])
@jwt_required()
def summarize_complaint():
    data = request.get_json()
    
    if not data.get('text'):
        return jsonify({'success': False, 'message': 'Text is required'}), 400
    
    summary = generate_summary_with_gemini(
        data['text'],
        data.get('location'),
        data.get('category')
    )
    
    return jsonify({
        'success': True,
        'summary': summary
    })

@app.route('/api/gemini/sentiment', methods=['POST'])
@jwt_required()
def analyze_sentiment():
    data = request.get_json()
    
    if not data.get('text'):
        return jsonify({'success': False, 'message': 'Text is required'}), 400
    
    sentiment = analyze_sentiment_with_gemini(data['text'])
    
    return jsonify({
        'success': True,
        'sentiment': sentiment
    })

# Complaint Routes
@app.route('/api/complaints', methods=['POST'])
@jwt_required()
def create_complaint():
    data = request.get_json()
    current_user_id = get_jwt_identity()
    
    # Validate required fields
    required_fields = ['title', 'description', 'location']
    if not all(k in data for k in required_fields):
        return jsonify({'success': False, 'message': 'Missing required fields'}), 400
    
    # Use Gemini AI for classification
    classification = classify_complaint_with_gemini(
        data['description'],
        data.get('location'),
        data.get('category')
    )
    
    summary = generate_summary_with_gemini(
        data['description'],
        data.get('location'),
        data.get('category')
    )
    
    # Create complaint
    complaint = Complaint(
        id=str(uuid.uuid4()),
        title=data['title'],
        description=data['description'],
        location=data['location'],
        category=data.get('category') or classification.get('category'),
        priority=data.get('priority') or classification.get('priority'),
        user_id=current_user_id,
        image_urls=data.get('image_urls', []),
        latitude=data.get('latitude'),
        longitude=data.get('longitude'),
        gemini_classification=classification.get('category'),
        gemini_summary=summary,
        gemini_keywords=classification.get('keywords', [])
    )
    
    db.session.add(complaint)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Complaint created successfully',
        'complaint': complaint.to_dict()
    }), 201

@app.route('/api/complaints/my', methods=['GET'])
@jwt_required()
def get_user_complaints():
    current_user_id = get_jwt_identity()
    page = request.args.get('page', 1, type=int)
    limit = request.args.get('limit', 20, type=int)
    status = request.args.get('status')
    category = request.args.get('category')
    
    query = Complaint.query.filter_by(user_id=current_user_id)
    
    if status:
        query = query.filter_by(status=status)
    if category:
        query = query.filter_by(category=category)
    
    complaints = query.paginate(
        page=page, per_page=limit, error_out=False
    )
    
    return jsonify({
        'success': True,
        'complaints': [complaint.to_dict() for complaint in complaints.items],
        'pagination': {
            'page': page,
            'limit': limit,
            'total': complaints.total,
            'pages': complaints.pages
        }
    })

@app.route('/api/complaints', methods=['GET'])
@require_role(['staff', 'admin'])
def get_all_complaints():
    page = request.args.get('page', 1, type=int)
    limit = request.args.get('limit', 20, type=int)
    status = request.args.get('status')
    category = request.args.get('category')
    priority = request.args.get('priority')
    assigned_to = request.args.get('assigned_to')
    
    query = Complaint.query
    
    if status:
        query = query.filter_by(status=status)
    if category:
        query = query.filter_by(category=category)
    if priority:
        query = query.filter_by(priority=priority)
    if assigned_to:
        query = query.filter_by(assigned_to=assigned_to)
    
    complaints = query.paginate(
        page=page, per_page=limit, error_out=False
    )
    
    return jsonify({
        'success': True,
        'complaints': [complaint.to_dict() for complaint in complaints.items],
        'pagination': {
            'page': page,
            'limit': limit,
            'total': complaints.total,
            'pages': complaints.pages
        }
    })

@app.route('/api/complaints/<complaint_id>/status', methods=['PUT'])
@require_role(['staff', 'admin'])
def update_complaint_status(complaint_id):
    data = request.get_json()
    
    complaint = Complaint.query.get(complaint_id)
    if not complaint:
        return jsonify({'success': False, 'message': 'Complaint not found'}), 404
    
    if 'status' in data:
        complaint.status = data['status']
    if 'notes' in data:
        complaint.notes = data['notes']
    if 'assigned_to' in data:
        complaint.assigned_to = data['assigned_to']
    
    complaint.updated_at = datetime.utcnow()
    
    if data.get('status') in ['resolved', 'closed']:
        complaint.resolved_at = datetime.utcnow()
    
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Complaint status updated',
        'complaint': complaint.to_dict()
    })

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("Database tables created successfully!")
        print("Server starting on http://0.0.0.0:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
