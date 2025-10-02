"""
CivicSense Backend - FastAPI Server
Handles Firebase token verification and secure database operations
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth
import asyncpg
import os
import json
import uuid
from datetime import datetime, timezone
from typing import Optional, List
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="CivicSense API",
    description="Backend API for CivicSense complaint management system",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Database connection
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/civic_sense")

# Initialize Firebase Admin SDK
try:
    # Try to load service account key
    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    if service_account_path and os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    else:
        # For development, you can use default credentials
        firebase_admin.initialize_app()
    print("✅ Firebase Admin SDK initialized")
except Exception as e:
    print(f"❌ Firebase initialization failed: {e}")
    print("Please set FIREBASE_SERVICE_ACCOUNT_PATH in your .env file")

# Database connection pool
db_pool = None

async def get_db_pool():
    global db_pool
    if db_pool is None:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
    return db_pool

# Pydantic models
class UserCreate(BaseModel):
    name: str
    email: str
    firebase_uid: str
    role: str = "citizen"
    phone: Optional[str] = None

class UserResponse(BaseModel):
    user_id: int
    firebase_uid: str
    name: str
    email: str
    role: str
    is_active: bool
    created_at: datetime

class ComplaintCreate(BaseModel):
    title: str
    description: str
    issue_type: str
    image_url: Optional[str] = None
    location_lat: float
    location_lng: float
    city: Optional[str] = None
    zone: Optional[str] = None
    priority: str = "medium"

class ComplaintResponse(BaseModel):
    complaint_id: str
    user_id: int
    title: str
    description: str
    issue_type: str
    image_url: Optional[str]
    location_lat: float
    location_lng: float
    city: Optional[str]
    zone: Optional[str]
    priority: str
    status: str
    created_at: datetime
    updated_at: datetime

class StatusUpdate(BaseModel):
    status: str
    remarks: Optional[str] = None

# Firebase token verification
async def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        # Remove 'Bearer ' prefix if present
        token = credentials.credentials
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Verify the token with Firebase
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}"
        )

# Get user from database by Firebase UID
async def get_user_by_firebase_uid(firebase_uid: str, pool: asyncpg.Pool):
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM users WHERE firebase_uid = $1 AND is_active = true",
            firebase_uid
        )
        return row

# Auth endpoints
@app.post("/api/auth/signup", response_model=UserResponse)
async def signup(user_data: UserCreate):
    """Create a new user in the database after Firebase signup"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as conn:
            # Check if user already exists
            existing_user = await conn.fetchrow(
                "SELECT * FROM users WHERE firebase_uid = $1 OR email = $2",
                user_data.firebase_uid, user_data.email
            )
            
            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User already exists"
                )
            
            # Insert new user
            row = await conn.fetchrow(
                """
                INSERT INTO users (firebase_uid, name, email, role, phone, is_active, created_at)
                VALUES ($1, $2, $3, $4, $5, true, $6)
                RETURNING user_id, firebase_uid, name, email, role, is_active, created_at
                """,
                user_data.firebase_uid,
                user_data.name,
                user_data.email,
                user_data.role,
                user_data.phone,
                datetime.now(timezone.utc)
            )
            
            return UserResponse(**dict(row))
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )

@app.get("/api/auth/me", response_model=UserResponse)
async def get_current_user(decoded_token: dict = Depends(verify_firebase_token)):
    """Get current user information"""
    pool = await get_db_pool()
    firebase_uid = decoded_token['uid']
    
    user = await get_user_by_firebase_uid(firebase_uid, pool)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserResponse(**dict(user))

# Complaint endpoints
@app.post("/api/complaints", response_model=ComplaintResponse)
async def create_complaint(
    complaint_data: ComplaintCreate,
    decoded_token: dict = Depends(verify_firebase_token)
):
    """Create a new complaint"""
    pool = await get_db_pool()
    firebase_uid = decoded_token['uid']
    
    # Get user from database
    user = await get_user_by_firebase_uid(firebase_uid, pool)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    try:
        async with pool.acquire() as conn:
            # Find appropriate department based on location
            dept_id = await find_department_by_location(
                conn, complaint_data.location_lat, complaint_data.location_lng
            )
            
            # Insert complaint
            complaint_id = str(uuid.uuid4())
            row = await conn.fetchrow(
                """
                INSERT INTO complaints (
                    complaint_id, user_id, dept_id, title, description, issue_type,
                    image_url, location_lat, location_lng, city, zone, priority,
                    status, created_at, updated_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'submitted', $13, $13)
                RETURNING *
                """,
                complaint_id,
                user['user_id'],
                dept_id,
                complaint_data.title,
                complaint_data.description,
                complaint_data.issue_type,
                complaint_data.image_url,
                complaint_data.location_lat,
                complaint_data.location_lng,
                complaint_data.city,
                complaint_data.zone,
                complaint_data.priority,
                datetime.now(timezone.utc)
            )
            
            return ComplaintResponse(**dict(row))
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create complaint: {str(e)}"
        )

@app.get("/api/complaints", response_model=List[ComplaintResponse])
async def get_user_complaints(decoded_token: dict = Depends(verify_firebase_token)):
    """Get complaints for the current user"""
    pool = await get_db_pool()
    firebase_uid = decoded_token['uid']
    
    user = await get_user_by_firebase_uid(firebase_uid, pool)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM complaints WHERE user_id = $1 ORDER BY created_at DESC",
                user['user_id']
            )
            
            return [ComplaintResponse(**dict(row)) for row in rows]
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch complaints: {str(e)}"
        )

@app.get("/api/complaints/assigned", response_model=List[ComplaintResponse])
async def get_assigned_complaints(decoded_token: dict = Depends(verify_firebase_token)):
    """Get complaints assigned to the current staff member"""
    pool = await get_db_pool()
    firebase_uid = decoded_token['uid']
    
    user = await get_user_by_firebase_uid(firebase_uid, pool)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user['role'] not in ['staff', 'admin']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Staff or admin role required."
        )
    
    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM complaints WHERE assigned_worker_id = $1 ORDER BY created_at DESC",
                user['user_id']
            )
            
            return [ComplaintResponse(**dict(row)) for row in rows]
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch assigned complaints: {str(e)}"
        )

@app.patch("/api/complaints/{complaint_id}/status")
async def update_complaint_status(
    complaint_id: str,
    status_update: StatusUpdate,
    decoded_token: dict = Depends(verify_firebase_token)
):
    """Update complaint status (staff/admin only)"""
    pool = await get_db_pool()
    firebase_uid = decoded_token['uid']
    
    user = await get_user_by_firebase_uid(firebase_uid, pool)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user['role'] not in ['staff', 'admin']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Staff or admin role required."
        )
    
    try:
        async with pool.acquire() as conn:
            # Update complaint status
            await conn.execute(
                """
                UPDATE complaints 
                SET status = $1, updated_at = $2
                WHERE complaint_id = $3
                """,
                status_update.status,
                datetime.now(timezone.utc),
                complaint_id
            )
            
            # Add to complaint history
            await conn.execute(
                """
                INSERT INTO complaint_history (complaint_id, status, remarks, changed_by, created_at)
                VALUES ($1, $2, $3, $4, $5)
                """,
                complaint_id,
                status_update.status,
                status_update.remarks,
                user['user_id'],
                datetime.now(timezone.utc)
            )
            
            return {"message": "Status updated successfully"}
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update status: {str(e)}"
        )

# Helper functions
async def find_department_by_location(conn: asyncpg.Connection, lat: float, lng: float) -> Optional[int]:
    """Find the appropriate department for a given location"""
    try:
        # Try PostGIS query first (if available)
        row = await conn.fetchrow(
            """
            SELECT department_id 
            FROM govt_bodies 
            WHERE ST_Contains(jurisdiction_polygon, ST_SetSRID(ST_MakePoint($1, $2), 4326))
            LIMIT 1
            """,
            lng, lat
        )
        if row:
            return row['department_id']
    except:
        # Fallback to nearest point if PostGIS not available
        row = await conn.fetchrow(
            """
            SELECT department_id,
                   (3959 * acos(cos(radians($1)) * cos(radians(location_lat)) * 
                    cos(radians(location_lon) - radians($2)) + 
                    sin(radians($1)) * sin(radians(location_lat)))) AS distance
            FROM govt_bodies
            WHERE location_lat IS NOT NULL AND location_lon IS NOT NULL
            ORDER BY distance
            LIMIT 1
            """,
            lat, lng
        )
        if row:
            return row['department_id']
    
    # Default department if no match found
    return 1

# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc)}

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize database connection pool on startup"""
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
        print("✅ Database connection pool created")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection pool on shutdown"""
    global db_pool
    if db_pool:
        await db_pool.close()
        print("✅ Database connection pool closed")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
