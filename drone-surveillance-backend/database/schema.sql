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

-- 6. flight_logs
CREATE TABLE flight_logs (
    log_id SERIAL PRIMARY KEY,
    mission_id INTEGER REFERENCES flight_missions(mission_id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    start_lat DECIMAL(9,6),
    start_lng DECIMAL(9,6),
    end_lat DECIMAL(9,6),
    end_lng DECIMAL(9,6),
    logged_at TIMESTAMP DEFAULT NOW()
);

-- 7. detected_objects
CREATE TABLE detected_objects (
    detection_id SERIAL PRIMARY KEY,
    log_id INTEGER REFERENCES flight_logs(log_id) ON DELETE CASCADE,
    object_type VARCHAR(100) NOT NULL,
    threat_level VARCHAR(20) CHECK (threat_level IN ('Low', 'Medium', 'High')) NOT NULL,
    detected_at TIMESTAMP DEFAULT NOW(),
    coordinates_lat DECIMAL(9,6),
    coordinates_lng DECIMAL(9,6),
    description TEXT
);

-- 8. alerts
CREATE TABLE alerts (
    alert_id SERIAL PRIMARY KEY,
    detection_id INTEGER REFERENCES detected_objects(detection_id) ON DELETE CASCADE,
    alert_status VARCHAR(30) CHECK (alert_status IN ('New', 'Acknowledged', 'Resolved')) DEFAULT 'New',
    severity VARCHAR(20) CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')) NOT NULL,
    generated_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL
);

-- 9. incident_reports
CREATE TABLE incident_reports (
    incident_id SERIAL PRIMARY KEY,
    alert_id INTEGER REFERENCES alerts(alert_id) ON DELETE CASCADE,
    reported_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    incident_status VARCHAR(30) CHECK (incident_status IN ('Open', 'Under Review', 'Resolved', 'Archived')) DEFAULT 'Open',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 10. audit_log
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER,
    description TEXT,
    performed_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_flight_logs_mission ON flight_logs(mission_id);
CREATE INDEX idx_detected_objects_log ON detected_objects(log_id);
CREATE INDEX idx_detected_objects_threat ON detected_objects(threat_level);
CREATE INDEX idx_alerts_status ON alerts(alert_status);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_flight_missions_drone ON flight_missions(drone_id);
CREATE INDEX idx_flight_missions_zone ON flight_missions(zone_id);


-- ============================================================
-- Trigger: auto-generate alert for High threat detections
-- ============================================================
CREATE OR REPLACE FUNCTION auto_generate_alert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.threat_level = 'High' THEN
        INSERT INTO alerts (detection_id, alert_status, severity, generated_at)
        VALUES (NEW.detection_id, 'New', 'Critical', NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_generate_alert
AFTER INSERT ON detected_objects
FOR EACH ROW
EXECUTE FUNCTION auto_generate_alert();

-- ============================================================
-- Views
-- ============================================================
CREATE OR REPLACE VIEW analyst_alert_view AS
SELECT
    a.alert_id,
    a.severity,
    a.alert_status,
    a.generated_at,
    d.object_type,
    d.threat_level,
    sz.zone_name,
    dr.drone_name
FROM alerts a
JOIN detected_objects d ON a.detection_id = d.detection_id
JOIN flight_logs fl ON d.log_id = fl.log_id
JOIN flight_missions fm ON fl.mission_id = fm.mission_id
JOIN drones dr ON fm.drone_id = dr.drone_id
JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id;

CREATE OR REPLACE VIEW operator_mission_view AS
SELECT
    fm.mission_id,
    dr.drone_name,
    sz.zone_name,
    u.full_name AS operator_name,
    fm.scheduled_time,
    fm.mission_status
FROM flight_missions fm
JOIN drones dr ON fm.drone_id = dr.drone_id
JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
LEFT JOIN users u ON fm.operator_id = u.user_id;


-- ============================================================
-- Stored Procedures
-- ============================================================
CREATE OR REPLACE PROCEDURE update_incident_status(
    p_incident_id INT,
    p_new_status VARCHAR,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE incident_reports
    SET incident_status = p_new_status,
        updated_at = NOW()
    WHERE incident_id = p_incident_id;

    INSERT INTO audit_log (user_id, action, table_name, record_id, description, performed_at)
    VALUES (
        p_user_id,
        'UPDATE_STATUS',
        'incident_reports',
        p_incident_id,
        'Incident status changed to ' || p_new_status,
        NOW()
    );
END;
$$;

CREATE OR REPLACE FUNCTION get_drone_utilization_report()
RETURNS TABLE (
    drone_name VARCHAR,
    total_missions BIGINT,
    total_flight_minutes BIGINT,
    zones_covered BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.drone_name,
        COUNT(DISTINCT fm.mission_id) AS total_missions,
        COALESCE(SUM(fl.duration_minutes), 0) AS total_flight_minutes,
        COUNT(DISTINCT fm.zone_id) AS zones_covered
    FROM drones d
    LEFT JOIN flight_missions fm ON d.drone_id = fm.drone_id
    LEFT JOIN flight_logs fl ON fm.mission_id = fl.mission_id
    GROUP BY d.drone_id, d.drone_name
    ORDER BY total_missions DESC;
END;
$$;
