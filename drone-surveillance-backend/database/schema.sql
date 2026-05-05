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

