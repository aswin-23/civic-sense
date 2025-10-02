-- CivicSense Database Schema
-- PostgreSQL with PostGIS extension (optional but recommended)

-- Enable PostGIS extension (uncomment if you have PostGIS installed)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    firebase_uid TEXT UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) CHECK (role IN ('citizen','staff','admin')) DEFAULT 'citizen',
    zone VARCHAR(100),  -- for staff: assigned zone
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Departments table
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(150) NOT NULL,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Government bodies table (for jurisdiction mapping)
CREATE TABLE govt_bodies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    department_id INT REFERENCES departments(dept_id),
    location_lat DOUBLE PRECISION,
    location_lon DOUBLE PRECISION,
    contact_url TEXT,
    -- PostGIS polygon for jurisdiction (uncomment if PostGIS is available)
    -- jurisdiction_polygon GEOMETRY(MULTIPOLYGON,4326),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Complaints table
CREATE TABLE complaints (
    complaint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT REFERENCES users(user_id) ON DELETE SET NULL,
    dept_id INT REFERENCES departments(dept_id),
    assigned_worker_id INT REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    issue_type VARCHAR(120),   -- from Gemini classification
    image_url TEXT,            -- main image URL or JSON array
    location_lat DOUBLE PRECISION NOT NULL,
    location_lng DOUBLE PRECISION NOT NULL,
    city VARCHAR(100),
    zone VARCHAR(100),
    priority VARCHAR(10) CHECK (priority IN ('low','medium','high')) DEFAULT 'medium',
    status VARCHAR(20) CHECK (status IN ('submitted','forwarded','acknowledged','in_progress','resolved','rejected')) DEFAULT 'submitted',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Complaint media table (one-to-many relationship)
CREATE TABLE complaint_media (
    id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    media_type VARCHAR(50) CHECK (media_type IN ('citizen_submission', 'worker_resolution')),
    url TEXT NOT NULL,
    uploaded_by INT REFERENCES users(user_id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Complaint history/audit table
CREATE TABLE complaint_history (
    history_id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    status VARCHAR(20),
    remarks TEXT,
    changed_by INT REFERENCES users(user_id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- User device tokens for push notifications
CREATE TABLE user_device_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('android', 'ios', 'web')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_complaints_user_id ON complaints(user_id);
CREATE INDEX idx_complaints_dept_id ON complaints(dept_id);
CREATE INDEX idx_complaints_assigned_worker_id ON complaints(assigned_worker_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_created_at ON complaints(created_at);
CREATE INDEX idx_complaints_location ON complaints(location_lat, location_lng);

-- PostGIS spatial index (uncomment if PostGIS is available)
-- CREATE INDEX idx_govt_bodies_jurisdiction ON govt_bodies USING GIST (jurisdiction_polygon);

CREATE INDEX idx_complaint_media_complaint_id ON complaint_media(complaint_id);
CREATE INDEX idx_complaint_history_complaint_id ON complaint_history(complaint_id);
CREATE INDEX idx_user_device_tokens_user_id ON user_device_tokens(user_id);

-- Sample data
INSERT INTO departments (dept_name, contact_email, contact_phone) VALUES
('Public Works Department', 'pwd@city.gov', '+1-555-0101'),
('Environmental Services', 'env@city.gov', '+1-555-0102'),
('Traffic Management', 'traffic@city.gov', '+1-555-0103'),
('Parks and Recreation', 'parks@city.gov', '+1-555-0104'),
('Public Safety', 'safety@city.gov', '+1-555-0105');

-- Sample government bodies with locations
INSERT INTO govt_bodies (name, department_id, location_lat, location_lon, contact_url) VALUES
('City Hall', 1, 40.7128, -74.0060, 'https://city.gov/hall'),
('Public Works Office - Downtown', 1, 40.7589, -73.9851, 'https://city.gov/pwd-downtown'),
('Environmental Services - North', 2, 40.7831, -73.9712, 'https://city.gov/env-north'),
('Traffic Control Center', 3, 40.7505, -73.9934, 'https://city.gov/traffic'),
('Central Park Office', 4, 40.7829, -73.9654, 'https://city.gov/parks'),
('Police Headquarters', 5, 40.7128, -74.0060, 'https://city.gov/police');

-- Sample admin user (you'll need to replace firebase_uid with actual Firebase UID)
-- INSERT INTO users (firebase_uid, name, email, role, zone) VALUES
-- ('your-firebase-admin-uid', 'Admin User', 'admin@city.gov', 'admin', 'all');

-- Update triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_device_tokens_updated_at BEFORE UPDATE ON user_device_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
