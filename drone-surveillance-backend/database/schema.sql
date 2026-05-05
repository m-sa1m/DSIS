-- ============================================================
-- Drone Surveillance & Intelligence System — Schema
-- GIK Institute of Engineering Sciences and Technology
-- ============================================================

-- Drop existing objects in reverse dependency order
DROP VIEW IF EXISTS operator_mission_view CASCADE;
DROP VIEW IF EXISTS analyst_alert_view CASCADE;
DROP TRIGGER IF EXISTS trg_auto_generate_alert ON detected_objects;
DROP FUNCTION IF EXISTS auto_generate_alert();
DROP FUNCTION IF EXISTS update_incident_status(INT, VARCHAR, INT);
DROP FUNCTION IF EXISTS get_drone_utilization_report();
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS incident_reports CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS detected_objects CASCADE;
DROP TABLE IF EXISTS flight_logs CASCADE;
DROP TABLE IF EXISTS flight_missions CASCADE;
DROP TABLE IF EXISTS drones CASCADE;
DROP TABLE IF EXISTS surveillance_zones CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 1. roles
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- 2. users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role_id INTEGER REFERENCES roles(role_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 4. surveillance_zones (created before drones due to FK dependency)
CREATE TABLE surveillance_zones (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    location_description TEXT,
    risk_level VARCHAR(20) CHECK (risk_level IN ('Low', 'Medium', 'High')) DEFAULT 'Low',
    coordinates_lat DECIMAL(9,6),
    coordinates_lng DECIMAL(9,6)
);

-- 3. drones
CREATE TABLE drones (
    drone_id SERIAL PRIMARY KEY,
    drone_name VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    status VARCHAR(30) CHECK (status IN ('Active', 'Inactive', 'Under Maintenance')) DEFAULT 'Active',
    zone_id INTEGER REFERENCES surveillance_zones(zone_id) ON DELETE SET NULL,
    registered_at TIMESTAMP DEFAULT NOW()
);

-- 5. flight_missions
CREATE TABLE flight_missions (
    mission_id SERIAL PRIMARY KEY,
    drone_id INTEGER REFERENCES drones(drone_id) ON DELETE CASCADE,
    zone_id INTEGER REFERENCES surveillance_zones(zone_id) ON DELETE SET NULL,
    operator_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    scheduled_time TIMESTAMP NOT NULL,
    mission_status VARCHAR(30) CHECK (mission_status IN ('Scheduled', 'In Progress', 'Completed', 'Aborted')) DEFAULT 'Scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);