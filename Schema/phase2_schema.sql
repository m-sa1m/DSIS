-- ============================================================================================================================
--  ____  ____  ___  _   _ _____   ____  _   _ ______     _______ _____  _____  _      _      _____ _____ _   _ ______ ______
-- |  _ \|  _ \/ _ \| \ | | ____| / ___|| | | |  _ \ \   / / ____|_   _|| ____|| |    | |    |_   _/ ____| \ | / _____|  ____|
-- | | | | |_) | | | |  \| |  _|   \___ \| | | | |_) \ \ / /|  _|  | |  |  _|  | |    | |      | || |  __|  \| | |   | |__
-- | |_| |  _ <| |_| | |\  | |___   ___) | |_| |  _ < \ V / | |___ | |  | |___ | |___ | |___  _| || |_| | |\  | |___| |____
-- |____/|_| \_\\___/|_| \_|_____| |____/ \___/|_| \_\ \_/  |_____||_|  |_____||_____|_____|  \___\\_____|_| \_|\_____|______|
--
--  ██████╗██╗   ██╗██████╗ ███████╗███████╗    ███████╗██╗   ██╗██████╗ ██╗   ██╗███████╗██╗██╗     ██╗      █████╗ ███╗   ██╗ ██████╗███████╗
-- ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔════╝    ██╔════╝██║   ██║██╔══██╗██║   ██║██╔════╝██║██║     ██║     ██╔══██╗████╗  ██║██╔════╝██╔════╝
-- ██║      ╚████╔╝ ██████╔╝█████╗  ███████╗    ███████╗██║   ██║██████╔╝██║   ██║█████╗  ██║██║     ██║     ███████║██╔██╗ ██║██║     █████╗
-- ██║       ╚██╔╝  ██╔══██╗██╔══╝  ╚════██║    ╚════██║██║   ██║██╔══██╗╚██╗ ██╔╝██╔══╝  ██║██║     ██║     ██╔══██║██║╚██╗██║██║     ██╔══╝
-- ╚██████╗   ██║   ██████╔╝███████╗███████║    ███████║╚██████╔╝██║  ██║ ╚████╔╝ ███████╗██║███████╗███████╗██║  ██║██║ ╚████║╚██████╗███████╗
--  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚══════╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
--
-- ============================================================================================================================
-- PROJECT      : Drone Surveillance & Intelligence System (DSIS)
-- PHASE        : Phase 2 — Complete Database Design & Schema Implementation
-- AUTHOR       : Muhammad Saim | Reg# 2024453 | CYS
-- COURSE       : Database Systems
-- DATABASE     : PostgreSQL 16+
-- ENCODING     : UTF-8
-- VERSION      : 1.0.0
-- DATE         : April 2025
-- ============================================================================================================================
-- DESIGN PRINCIPLES:
--   1. Full 3NF / BCNF normalization across all 21+ tables
--   2. Referential integrity enforced via FK constraints with explicit ON DELETE policies
--   3. Custom ENUM domains for type safety (no magic strings)
--   4. Composite & partial indexes for analytical workloads
--   5. Table partitioning on high-volume tables (detected_objects, audit_log)
--   6. Row-level security (RLS) policies on sensitive tables
--   7. Check constraints for business rule enforcement
--   8. Automatic updated_at timestamps via trigger
--   9. UUID primary keys on all core entities for distributed-system readiness
--  10. Full inline documentation via COMMENT ON statements
-- ============================================================================================================================

-- ============================================================================================================================
-- SECTION 0: ENVIRONMENT SETUP
-- ============================================================================================================================

-- Ensure we are working with a clean, dedicated schema
-- Run this in psql as superuser:  \i phase2_schema.sql

SET client_encoding = 'UTF8';
SET standard_conforming_strings = ON;
SET check_function_bodies = FALSE;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";          -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";            -- Secure password hashing
CREATE EXTENSION IF NOT EXISTS "btree_gist";          -- GiST index support for exclusion constraints
CREATE EXTENSION IF NOT EXISTS "pg_trgm";             -- Trigram indexes for LIKE queries
CREATE EXTENSION IF NOT EXISTS "postgis" CASCADE;     -- Geospatial support (optional, comment out if not installed)
-- Note: Install PostGIS with:  sudo apt install postgresql-16-postgis-3

-- Create dedicated schema
DROP SCHEMA IF EXISTS dsis CASCADE;
CREATE SCHEMA dsis;
SET search_path = dsis, public;

COMMENT ON SCHEMA dsis IS 'Drone Surveillance & Intelligence System — primary application schema';

-- ============================================================================================================================
-- SECTION 1: CUSTOM DOMAINS & ENUM TYPES
-- (Centralising all categorical values — prevents magic strings throughout the schema)
-- ============================================================================================================================

-- User & Access
CREATE TYPE dsis.user_status_t       AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');
CREATE TYPE dsis.role_name_t         AS ENUM ('super_admin', 'admin', 'operator', 'analyst', 'viewer');
CREATE TYPE dsis.auth_method_t       AS ENUM ('password', 'oauth2', 'api_key', 'mfa');

-- Drone & Fleet
CREATE TYPE dsis.drone_status_t      AS ENUM ('idle', 'in_mission', 'charging', 'maintenance', 'decommissioned', 'lost');
CREATE TYPE dsis.drone_model_t       AS ENUM ('fixed_wing', 'quadcopter', 'hexacopter', 'octocopter', 'hybrid_vtol');
CREATE TYPE dsis.health_metric_t     AS ENUM ('battery', 'motor', 'gps', 'camera', 'compass', 'lidar', 'firmware');
CREATE TYPE dsis.health_status_t     AS ENUM ('optimal', 'degraded', 'critical', 'unknown');

-- Zones & Missions
CREATE TYPE dsis.zone_type_t         AS ENUM ('campus', 'border', 'industrial', 'urban', 'rural', 'maritime', 'restricted');
CREATE TYPE dsis.risk_level_t        AS ENUM ('low', 'moderate', 'high', 'critical');
CREATE TYPE dsis.mission_status_t    AS ENUM ('planned', 'briefing', 'in_progress', 'completed', 'aborted', 'failed');
CREATE TYPE dsis.mission_type_t      AS ENUM ('routine_patrol', 'incident_response', 'perimeter_check', 'evidence_collection', 'training');

-- Detection & Threats
CREATE TYPE dsis.threat_level_t      AS ENUM ('none', 'low', 'medium', 'high', 'critical');
CREATE TYPE dsis.object_category_t   AS ENUM ('person', 'vehicle', 'weapon', 'animal', 'aircraft', 'watercraft', 'package', 'unknown');
CREATE TYPE dsis.movement_t          AS ENUM ('stationary', 'walking', 'running', 'driving', 'flying', 'unknown');

-- Alerts & Incidents
CREATE TYPE dsis.alert_status_t      AS ENUM ('open', 'acknowledged', 'in_progress', 'resolved', 'false_positive', 'escalated');
CREATE TYPE dsis.alert_severity_t    AS ENUM ('info', 'low', 'medium', 'high', 'critical');
CREATE TYPE dsis.incident_status_t   AS ENUM ('open', 'under_review', 'resolved', 'archived', 'cancelled');
CREATE TYPE dsis.escalation_action_t AS ENUM ('acknowledged', 'reassigned', 'escalated_up', 'dispatched', 'closed', 'flagged');

-- Evidence & Media
CREATE TYPE dsis.evidence_type_t     AS ENUM ('image', 'video', 'audio', 'telemetry_log', 'report_pdf', 'other');
CREATE TYPE dsis.storage_tier_t      AS ENUM ('hot', 'warm', 'cold', 'archived');

-- Weather
CREATE TYPE dsis.weather_condition_t AS ENUM ('clear', 'cloudy', 'partly_cloudy', 'rain', 'heavy_rain', 'fog', 'snow', 'thunderstorm', 'sandstorm', 'haze');
CREATE TYPE dsis.flight_clearance_t  AS ENUM ('approved', 'marginal', 'not_recommended', 'grounded');

-- Analytics & Audit
CREATE TYPE dsis.prediction_model_t  AS ENUM ('threat_forecast', 'anomaly_detection', 'zone_risk_score', 'drone_failure_predict');
CREATE TYPE dsis.audit_action_t      AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'SELECT', 'LOGIN', 'LOGOUT', 'PERMISSION_CHANGE', 'SCHEMA_CHANGE');

-- ============================================================================================================================
-- SECTION 2: UTILITY FUNCTIONS
-- ============================================================================================================================

-- Auto-update updated_at column
CREATE OR REPLACE FUNCTION dsis.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION dsis.fn_set_updated_at() IS
    'Universal trigger function — automatically sets updated_at to current timestamp on every row update';

-- Generate a short human-readable reference code (e.g., DRONE-7F3A, INC-4B2C)
CREATE OR REPLACE FUNCTION dsis.fn_generate_ref(prefix TEXT)
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT prefix || '-' || upper(substring(md5(random()::text), 1, 6));
$$;

COMMENT ON FUNCTION dsis.fn_generate_ref(TEXT) IS
    'Generates a short human-readable reference code with a given prefix. Used for incident numbers, mission IDs, etc.';

-- ============================================================================================================================
-- SECTION 3: USER MANAGEMENT & RBAC
-- Tables: roles, permissions, role_permissions, users, user_sessions
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 3.1 roles
-- -----------------------------------------------------------------
CREATE TABLE dsis.roles (
    role_id          UUID            DEFAULT uuid_generate_v4() NOT NULL,
    role_name        dsis.role_name_t                           NOT NULL,
    display_name     VARCHAR(60)                                NOT NULL,
    description      TEXT,
    is_system_role   BOOLEAN         DEFAULT FALSE              NOT NULL,  -- system roles cannot be deleted
    created_at       TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP  NOT NULL,

    CONSTRAINT pk_roles PRIMARY KEY (role_id),
    CONSTRAINT uq_roles_name UNIQUE (role_name)
);

COMMENT ON TABLE  dsis.roles               IS 'RBAC role definitions. System roles (super_admin, admin) are protected from deletion.';
COMMENT ON COLUMN dsis.roles.is_system_role IS 'When TRUE, this role cannot be deleted via normal application logic — only by superuser.';

INSERT INTO dsis.roles (role_name, display_name, description, is_system_role) VALUES
    ('super_admin', 'Super Administrator', 'Unrestricted access to all system resources and configuration', TRUE),
    ('admin',       'Administrator',       'Manage users, drones, zones, and view all reports',            TRUE),
    ('operator',    'Drone Operator',      'Launch missions, update drone status, log detections',          FALSE),
    ('analyst',     'Security Analyst',    'View detections, generate reports, manage incidents',           FALSE),
    ('viewer',      'Read-Only Viewer',    'Read-only access to dashboards and public reports',             FALSE);

-- -----------------------------------------------------------------
-- 3.2 permissions
-- -----------------------------------------------------------------
CREATE TABLE dsis.permissions (
    permission_id   UUID            DEFAULT uuid_generate_v4() NOT NULL,
    permission_code VARCHAR(80)                                NOT NULL,   -- e.g. 'drone:create', 'alert:escalate'
    resource        VARCHAR(40)                                NOT NULL,   -- e.g. 'drone', 'alert', 'incident'
    action          VARCHAR(20)                                NOT NULL,   -- e.g. 'create', 'read', 'update', 'delete'
    description     TEXT,
    created_at      TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP  NOT NULL,

    CONSTRAINT pk_permissions         PRIMARY KEY (permission_id),
    CONSTRAINT uq_permissions_code    UNIQUE (permission_code),
    CONSTRAINT chk_action_values      CHECK (action IN ('create','read','update','delete','execute','admin'))
);

COMMENT ON TABLE  dsis.permissions                IS 'Granular permission codes following resource:action convention.';
COMMENT ON COLUMN dsis.permissions.permission_code IS 'Dot-notation code, e.g. "alert:escalate". Used by the backend for authorization checks.';

INSERT INTO dsis.permissions (permission_code, resource, action, description) VALUES
    ('drone:create',          'drone',     'create',  'Register a new drone in the fleet'),
    ('drone:read',            'drone',     'read',    'View drone details and status'),
    ('drone:update',          'drone',     'update',  'Modify drone attributes and assignment'),
    ('drone:delete',          'drone',     'delete',  'Decommission or remove a drone record'),
    ('mission:create',        'mission',   'create',  'Plan and initiate a flight mission'),
    ('mission:read',          'mission',   'read',    'View mission details and flight logs'),
    ('mission:abort',         'mission',   'execute', 'Abort an in-progress mission'),
    ('detection:read',        'detection', 'read',    'View detected objects and threat data'),
    ('detection:create',      'detection', 'create',  'Log a new detection record'),
    ('alert:read',            'alert',     'read',    'View active and historical alerts'),
    ('alert:acknowledge',     'alert',     'execute', 'Acknowledge an open alert'),
    ('alert:escalate',        'alert',     'execute', 'Escalate alert to higher authority'),
    ('incident:create',       'incident',  'create',  'Open a new incident report'),
    ('incident:update',       'incident',  'update',  'Update incident status and notes'),
    ('incident:read',         'incident',  'read',    'View incident reports and evidence'),
    ('report:generate',       'report',    'execute', 'Generate analytical and utilization reports'),
    ('user:manage',           'user',      'admin',   'Create, update, deactivate user accounts'),
    ('zone:manage',           'zone',      'admin',   'Create and configure surveillance zones'),
    ('audit:read',            'audit',     'read',    'Access audit logs and system trails'),
    ('analytics:read',        'analytics', 'read',    'View predictive analytics and forecasts');

-- -----------------------------------------------------------------
-- 3.3 role_permissions  (M:N junction)
-- -----------------------------------------------------------------
CREATE TABLE dsis.role_permissions (
    role_id       UUID NOT NULL,
    permission_id UUID NOT NULL,
    granted_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    granted_by    UUID,    -- FK to users; NULL for bootstrap grants

    CONSTRAINT pk_role_permissions PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role          FOREIGN KEY (role_id)       REFERENCES dsis.roles(role_id)       ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission    FOREIGN KEY (permission_id) REFERENCES dsis.permissions(permission_id) ON DELETE CASCADE
);

COMMENT ON TABLE dsis.role_permissions IS 'Junction table mapping roles to their granted permissions (M:N).';

-- Grant permissions to roles (super_admin gets everything via application logic; explicit grants below for others)
INSERT INTO dsis.role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dsis.roles r, dsis.permissions p
WHERE r.role_name = 'super_admin';

INSERT INTO dsis.role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dsis.roles r, dsis.permissions p
WHERE r.role_name = 'admin'
  AND p.permission_code NOT IN ('audit:read');  -- admin cannot self-audit

INSERT INTO dsis.role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dsis.roles r, dsis.permissions p
WHERE r.role_name = 'operator'
  AND p.permission_code IN ('drone:read','drone:update','mission:create','mission:read',
                             'mission:abort','detection:create','detection:read','alert:read','alert:acknowledge');

INSERT INTO dsis.role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dsis.roles r, dsis.permissions p
WHERE r.role_name = 'analyst'
  AND p.permission_code IN ('detection:read','alert:read','alert:escalate','incident:create',
                             'incident:update','incident:read','report:generate','analytics:read');

INSERT INTO dsis.role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dsis.roles r, dsis.permissions p
WHERE r.role_name = 'viewer'
  AND p.permission_code IN ('drone:read','mission:read','detection:read','alert:read','incident:read');

-- -----------------------------------------------------------------
-- 3.4 users
-- -----------------------------------------------------------------
CREATE TABLE dsis.users (
    user_id            UUID            DEFAULT uuid_generate_v4() NOT NULL,
    role_id            UUID                                        NOT NULL,
    username           VARCHAR(50)                                 NOT NULL,
    email              VARCHAR(120)                                NOT NULL,
    password_hash      TEXT                                        NOT NULL,  -- stored as pgcrypto crypt() hash
    full_name          VARCHAR(100)                                NOT NULL,
    phone              VARCHAR(20),
    department         VARCHAR(80),
    employee_id        VARCHAR(30),                                            -- organisation employee number
    auth_method        dsis.auth_method_t  DEFAULT 'password'     NOT NULL,
    status             dsis.user_status_t  DEFAULT 'pending_verification' NOT NULL,
    last_login_at      TIMESTAMPTZ,
    login_attempt_count INT              DEFAULT 0                 NOT NULL,
    account_locked_at  TIMESTAMPTZ,                                            -- NULL = not locked
    must_change_pwd    BOOLEAN          DEFAULT TRUE               NOT NULL,
    created_at         TIMESTAMPTZ      DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    updated_at         TIMESTAMPTZ      DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    created_by         UUID,

    CONSTRAINT pk_users          PRIMARY KEY (user_id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email    UNIQUE (email),
    CONSTRAINT fk_users_role     FOREIGN KEY (role_id)     REFERENCES dsis.roles(role_id)  ON DELETE RESTRICT,
    CONSTRAINT fk_users_creator  FOREIGN KEY (created_by)  REFERENCES dsis.users(user_id)  ON DELETE SET NULL,
    CONSTRAINT chk_email_format  CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT chk_login_attempts CHECK (login_attempt_count >= 0)
);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON dsis.users
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

COMMENT ON TABLE  dsis.users                   IS 'System user accounts with RBAC role assignment and security tracking.';
COMMENT ON COLUMN dsis.users.password_hash     IS 'Stored using pgcrypto crypt() with bf (blowfish) algorithm. Never store plaintext.';
COMMENT ON COLUMN dsis.users.login_attempt_count IS 'Incremented on failed login. Account locks at 5 consecutive failures.';
COMMENT ON COLUMN dsis.users.account_locked_at IS 'Timestamp of account lockout. NULL means account is not locked.';

-- Seed users (passwords: Admin@1234 for admin, Op@1234 for operator, etc.)
INSERT INTO dsis.users (role_id, username, email, password_hash, full_name, department, status, must_change_pwd)
VALUES
    ((SELECT role_id FROM dsis.roles WHERE role_name = 'super_admin'),
     'superadmin', 'superadmin@dsis.gov', crypt('SuperAdmin@9999', gen_salt('bf')),
     'System Super Administrator', 'IT Security', 'active', FALSE),

    ((SELECT role_id FROM dsis.roles WHERE role_name = 'admin'),
     'admin_saim', 'saim.admin@dsis.gov', crypt('Admin@1234', gen_salt('bf')),
     'Muhammad Saim', 'Command Center', 'active', FALSE),

    ((SELECT role_id FROM dsis.roles WHERE role_name = 'operator'),
     'op_ali', 'ali.operator@dsis.gov', crypt('Op@1234', gen_salt('bf')),
     'Ali Hassan', 'Drone Operations', 'active', TRUE),

    ((SELECT role_id FROM dsis.roles WHERE role_name = 'analyst'),
     'analyst_zara', 'zara.analyst@dsis.gov', crypt('An@1234', gen_salt('bf')),
     'Zara Malik', 'Intelligence Analysis', 'active', TRUE),

    ((SELECT role_id FROM dsis.roles WHERE role_name = 'viewer'),
     'viewer_bilal', 'bilal.viewer@dsis.gov', crypt('Vi@1234', gen_salt('bf')),
     'Bilal Ahmed', 'Campus Security', 'active', TRUE);

-- -----------------------------------------------------------------
-- 3.5 user_sessions
-- -----------------------------------------------------------------
CREATE TABLE dsis.user_sessions (
    session_id     UUID          DEFAULT uuid_generate_v4() NOT NULL,
    user_id        UUID                                      NOT NULL,
    token_hash     TEXT                                      NOT NULL,   -- hashed JWT / session token
    ip_address     INET,
    user_agent     TEXT,
    created_at     TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    expires_at     TIMESTAMPTZ                               NOT NULL,
    revoked_at     TIMESTAMPTZ,                                           -- NULL = active
    revoke_reason  VARCHAR(100),

    CONSTRAINT pk_user_sessions   PRIMARY KEY (session_id),
    CONSTRAINT fk_session_user    FOREIGN KEY (user_id) REFERENCES dsis.users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_session_expiry CHECK (expires_at > created_at)
);

CREATE INDEX idx_sessions_user_id   ON dsis.user_sessions (user_id);
CREATE INDEX idx_sessions_token     ON dsis.user_sessions (token_hash) WHERE revoked_at IS NULL;

COMMENT ON TABLE dsis.user_sessions IS 'Active and historical user login sessions with token tracking for security auditing.';

-- ============================================================================================================================
-- SECTION 4: DRONE FLEET MANAGEMENT
-- Tables: drones, drone_status, drone_health_log
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 4.1 drones
-- -----------------------------------------------------------------
CREATE TABLE dsis.drones (
    drone_id          UUID               DEFAULT uuid_generate_v4() NOT NULL,
    drone_ref         VARCHAR(20)        GENERATED ALWAYS AS (
                                             'DRN-' || upper(substring(drone_id::text, 1, 6))
                                         ) STORED,                               -- human-readable ref code
    serial_number     VARCHAR(50)                                    NOT NULL,
    model_name        VARCHAR(80)                                    NOT NULL,
    model_type        dsis.drone_model_t                             NOT NULL,
    manufacturer      VARCHAR(80)                                    NOT NULL,
    manufacture_date  DATE,
    purchase_date     DATE,
    warranty_expiry   DATE,
    max_flight_time   SMALLINT                                       NOT NULL,   -- minutes per full charge
    max_range_km      NUMERIC(6,2)                                   NOT NULL,
    max_altitude_m    SMALLINT                                       NOT NULL,
    camera_specs      JSONB,                                                     -- flexible camera capability metadata
    payload_capacity_kg NUMERIC(5,2),
    notes             TEXT,
    is_active         BOOLEAN            DEFAULT TRUE                NOT NULL,
    created_at        TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    updated_at        TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    registered_by     UUID,

    CONSTRAINT pk_drones               PRIMARY KEY (drone_id),
    CONSTRAINT uq_drones_serial        UNIQUE (serial_number),
    CONSTRAINT fk_drones_registered_by FOREIGN KEY (registered_by) REFERENCES dsis.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_max_flight_time     CHECK (max_flight_time > 0),
    CONSTRAINT chk_max_range           CHECK (max_range_km > 0),
    CONSTRAINT chk_max_altitude        CHECK (max_altitude_m > 0)
);

CREATE TRIGGER trg_drones_updated_at
    BEFORE UPDATE ON dsis.drones
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

COMMENT ON TABLE  dsis.drones              IS 'Registered drone units in the surveillance fleet. Captures hardware specifications and lifecycle info.';
COMMENT ON COLUMN dsis.drones.drone_ref    IS 'Auto-generated human-readable identifier derived from UUID prefix. e.g. DRN-A3F91B.';
COMMENT ON COLUMN dsis.drones.camera_specs IS 'JSONB blob storing camera capabilities: resolution, zoom, thermal, night_vision, etc.';

INSERT INTO dsis.drones (serial_number, model_name, model_type, manufacturer, manufacture_date,
                          purchase_date, warranty_expiry, max_flight_time, max_range_km,
                          max_altitude_m, camera_specs, payload_capacity_kg, registered_by)
VALUES
    ('SN-DJI-M30T-001', 'DJI Matrice 30T', 'quadcopter', 'DJI Technology', '2023-01-15',
     '2023-03-01', '2025-03-01', 41, 15.00, 7000,
     '{"resolution":"48MP","thermal":true,"night_vision":true,"optical_zoom":200,"video_4k":true}'::jsonb,
     2.0, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),

    ('SN-AUTEL-EVO2-002', 'Autel EVO II Pro', 'hexacopter', 'Autel Robotics', '2022-06-20',
     '2022-09-01', '2024-09-01', 40, 9.00, 5500,
     '{"resolution":"6K","thermal":false,"night_vision":true,"optical_zoom":16,"video_4k":true}'::jsonb,
     1.5, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),

    ('SN-SKYDIO-X10-003', 'Skydio X10', 'quadcopter', 'Skydio Inc', '2023-11-01',
     '2024-01-10', '2026-01-10', 35, 10.00, 4500,
     '{"resolution":"50MP","thermal":true,"night_vision":true,"optical_zoom":32,"video_4k":true}'::jsonb,
     1.0, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),

    ('SN-PARROT-ANAFI-004', 'Parrot ANAFI USA', 'quadcopter', 'Parrot SA', '2021-07-10',
     '2021-10-01', '2023-10-01', 32, 4.00, 4755,
     '{"resolution":"21MP","thermal":true,"night_vision":false,"optical_zoom":32,"video_4k":true}'::jsonb,
     0.5, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),

    ('SN-WINGTRA-FW-005', 'WingtraOne GEN II', 'fixed_wing', 'Wingtra AG', '2023-05-01',
     '2023-07-15', '2025-07-15', 59, 65.00, 3800,
     '{"resolution":"61MP","thermal":false,"night_vision":false,"optical_zoom":1,"video_4k":false}'::jsonb,
     0.8, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim'));

-- -----------------------------------------------------------------
-- 4.2 drone_status  (current operational state — 1:1 with drones)
-- -----------------------------------------------------------------
CREATE TABLE dsis.drone_status (
    drone_status_id   UUID               DEFAULT uuid_generate_v4() NOT NULL,
    drone_id          UUID                                           NOT NULL,
    current_status    dsis.drone_status_t DEFAULT 'idle'            NOT NULL,
    battery_level     SMALLINT,                                               -- 0–100 %
    signal_strength   SMALLINT,                                               -- 0–100 %
    last_gps_lat      NUMERIC(10, 7),
    last_gps_lon      NUMERIC(10, 7),
    last_altitude_m   NUMERIC(8, 2),
    last_speed_kmh    NUMERIC(6, 2),
    active_mission_id UUID,                                                   -- FK added after missions table
    firmware_version  VARCHAR(20),
    last_seen_at      TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    updated_at        TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP  NOT NULL,

    CONSTRAINT pk_drone_status          PRIMARY KEY (drone_status_id),
    CONSTRAINT uq_drone_status_drone_id UNIQUE (drone_id),                   -- enforces 1:1
    CONSTRAINT fk_ds_drone              FOREIGN KEY (drone_id) REFERENCES dsis.drones(drone_id) ON DELETE CASCADE,
    CONSTRAINT chk_battery              CHECK (battery_level  BETWEEN 0 AND 100),
    CONSTRAINT chk_signal               CHECK (signal_strength BETWEEN 0 AND 100),
    CONSTRAINT chk_lat                  CHECK (last_gps_lat   BETWEEN -90  AND 90),
    CONSTRAINT chk_lon                  CHECK (last_gps_lon   BETWEEN -180 AND 180)
);

CREATE TRIGGER trg_drone_status_updated_at
    BEFORE UPDATE ON dsis.drone_status
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

COMMENT ON TABLE  dsis.drone_status            IS '1:1 extension of drones — tracks real-time operational state, GPS position, and battery.';
COMMENT ON COLUMN dsis.drone_status.battery_level IS 'Battery percentage 0-100. Application should warn operators when below 20%.';

-- Seed initial statuses
INSERT INTO dsis.drone_status (drone_id, current_status, battery_level, signal_strength, firmware_version)
SELECT drone_id,
       CASE serial_number
           WHEN 'SN-DJI-M30T-001'     THEN 'idle'::dsis.drone_status_t
           WHEN 'SN-AUTEL-EVO2-002'   THEN 'charging'::dsis.drone_status_t
           WHEN 'SN-SKYDIO-X10-003'   THEN 'idle'::dsis.drone_status_t
           WHEN 'SN-PARROT-ANAFI-004' THEN 'maintenance'::dsis.drone_status_t
           WHEN 'SN-WINGTRA-FW-005'   THEN 'idle'::dsis.drone_status_t
       END,
       CASE serial_number
           WHEN 'SN-DJI-M30T-001'     THEN 87
           WHEN 'SN-AUTEL-EVO2-002'   THEN 42
           WHEN 'SN-SKYDIO-X10-003'   THEN 100
           WHEN 'SN-PARROT-ANAFI-004' THEN 15
           WHEN 'SN-WINGTRA-FW-005'   THEN 78
       END,
       95, '3.1.10'
FROM dsis.drones;

-- -----------------------------------------------------------------
-- 4.3 drone_health_log
-- -----------------------------------------------------------------
CREATE TABLE dsis.drone_health_log (
    log_id           UUID               DEFAULT uuid_generate_v4() NOT NULL,
    drone_id         UUID                                           NOT NULL,
    metric           dsis.health_metric_t                          NOT NULL,
    status           dsis.health_status_t                          NOT NULL,
    value_numeric    NUMERIC(10, 4),                                          -- quantitative reading (e.g. voltage)
    value_text       VARCHAR(120),                                            -- qualitative note
    threshold_min    NUMERIC(10, 4),
    threshold_max    NUMERIC(10, 4),
    is_anomaly       BOOLEAN            DEFAULT FALSE               NOT NULL,
    anomaly_detail   TEXT,
    recorded_at      TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    recorded_by      UUID,                                                    -- NULL = automated telemetry

    CONSTRAINT pk_drone_health_log PRIMARY KEY (log_id),
    CONSTRAINT fk_dhl_drone        FOREIGN KEY (drone_id)    REFERENCES dsis.drones(drone_id)  ON DELETE CASCADE,
    CONSTRAINT fk_dhl_user         FOREIGN KEY (recorded_by) REFERENCES dsis.users(user_id)    ON DELETE SET NULL
);

CREATE INDEX idx_dhl_drone_id     ON dsis.drone_health_log (drone_id, recorded_at DESC);
CREATE INDEX idx_dhl_anomaly      ON dsis.drone_health_log (drone_id) WHERE is_anomaly = TRUE;
CREATE INDEX idx_dhl_metric       ON dsis.drone_health_log (metric, status, recorded_at DESC);

COMMENT ON TABLE  dsis.drone_health_log            IS 'Time-series health telemetry per drone. Each row = one sensor reading or manual inspection record.';
COMMENT ON COLUMN dsis.drone_health_log.is_anomaly  IS 'Flagged TRUE when value falls outside threshold_min/threshold_max range.';

-- Seed sample health log entries
INSERT INTO dsis.drone_health_log (drone_id, metric, status, value_numeric, threshold_min, threshold_max, is_anomaly)
SELECT d.drone_id, 'battery'::dsis.health_metric_t, 'optimal'::dsis.health_status_t,
       87.5, 20.0, 100.0, FALSE
FROM dsis.drones d WHERE d.serial_number = 'SN-DJI-M30T-001'
UNION ALL
SELECT d.drone_id, 'motor'::dsis.health_metric_t, 'degraded'::dsis.health_status_t,
       72.1, 80.0, 100.0, TRUE
FROM dsis.drones d WHERE d.serial_number = 'SN-PARROT-ANAFI-004'
UNION ALL
SELECT d.drone_id, 'gps'::dsis.health_metric_t, 'optimal'::dsis.health_status_t,
       14.0, 8.0, 20.0, FALSE
FROM dsis.drones d WHERE d.serial_number = 'SN-SKYDIO-X10-003';

-- ============================================================================================================================
-- SECTION 5: SURVEILLANCE ZONES
-- Tables: surveillance_zones, zone_risk_profile, drone_zone_assignments
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 5.1 surveillance_zones
-- -----------------------------------------------------------------
CREATE TABLE dsis.surveillance_zones (
    zone_id          UUID               DEFAULT uuid_generate_v4() NOT NULL,
    zone_code        VARCHAR(20)                                    NOT NULL,  -- e.g., 'ZONE-ALPHA', 'ZONE-B3'
    zone_name        VARCHAR(100)                                   NOT NULL,
    zone_type        dsis.zone_type_t                               NOT NULL,
    description      TEXT,
    country          VARCHAR(60)                                    NOT NULL,
    region           VARCHAR(60),
    city             VARCHAR(60),
    address          TEXT,
    center_lat       NUMERIC(10, 7)                                 NOT NULL,
    center_lon       NUMERIC(10, 7)                                 NOT NULL,
    radius_km        NUMERIC(6, 3),                                            -- circular zone radius
    area_sq_km       NUMERIC(10, 4),                                           -- calculated or manual area
    geojson_boundary JSONB,                                                    -- GeoJSON polygon for irregular zones
    altitude_ceiling_m SMALLINT,                                               -- maximum allowed drone altitude in zone
    is_restricted    BOOLEAN            DEFAULT FALSE               NOT NULL,  -- restricted airspace
    is_active        BOOLEAN            DEFAULT TRUE                NOT NULL,
    created_at       TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    updated_at       TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    created_by       UUID,

    CONSTRAINT pk_surveillance_zones    PRIMARY KEY (zone_id),
    CONSTRAINT uq_zones_code            UNIQUE (zone_code),
    CONSTRAINT fk_zones_created_by      FOREIGN KEY (created_by) REFERENCES dsis.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_center_lat           CHECK (center_lat BETWEEN -90  AND 90),
    CONSTRAINT chk_center_lon           CHECK (center_lon BETWEEN -180 AND 180),
    CONSTRAINT chk_radius               CHECK (radius_km > 0),
    CONSTRAINT chk_altitude_ceiling     CHECK (altitude_ceiling_m > 0)
);

CREATE TRIGGER trg_zones_updated_at
    BEFORE UPDATE ON dsis.surveillance_zones
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

CREATE INDEX idx_zones_type_active ON dsis.surveillance_zones (zone_type, is_active);
CREATE INDEX idx_zones_geo         ON dsis.surveillance_zones (center_lat, center_lon);

COMMENT ON TABLE  dsis.surveillance_zones                IS 'Defined geographic zones monitored by the drone surveillance network.';
COMMENT ON COLUMN dsis.surveillance_zones.geojson_boundary IS 'Optional GeoJSON Polygon for irregular zone boundaries. Use PostGIS for spatial queries.';

INSERT INTO dsis.surveillance_zones (zone_code, zone_name, zone_type, country, region, city,
                                      center_lat, center_lon, radius_km, area_sq_km,
                                      altitude_ceiling_m, is_restricted, created_by)
VALUES
    ('ZONE-ALPHA',  'North Campus Perimeter',       'campus',     'Pakistan', 'Punjab',   'Islamabad',  33.7295, 73.0931, 0.800, 2.01,  120, FALSE,
     (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),
    ('ZONE-BRAVO',  'East Industrial Corridor',     'industrial', 'Pakistan', 'Punjab',   'Rawalpindi', 33.6007, 73.0679, 1.500, 7.07,  200, FALSE,
     (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),
    ('ZONE-CHARLIE','Border Sector 7 North',        'border',     'Pakistan', 'KPK',      'Topi',       34.0786, 72.6149, 3.000, 28.27, 400, TRUE,
     (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),
    ('ZONE-DELTA',  'City Centre Surveillance Grid','urban',      'Pakistan', 'Punjab',   'Lahore',     31.5204, 74.3587, 2.000, 12.57, 150, FALSE,
     (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')),
    ('ZONE-ECHO',   'Coastal Maritime Watch',       'maritime',   'Pakistan', 'Sindh',    'Karachi',    24.8607, 67.0011, 5.000, 78.54, 300, TRUE,
     (SELECT user_id FROM dsis.users WHERE username = 'admin_saim'));

-- -----------------------------------------------------------------
-- 5.2 zone_risk_profile
-- -----------------------------------------------------------------
CREATE TABLE dsis.zone_risk_profile (
    profile_id          UUID              DEFAULT uuid_generate_v4() NOT NULL,
    zone_id             UUID                                          NOT NULL,
    risk_level          dsis.risk_level_t DEFAULT 'low'              NOT NULL,
    risk_score          NUMERIC(5, 2),                                          -- 0.00 to 100.00 computed risk score
    incident_count_30d  INTEGER           DEFAULT 0                  NOT NULL,  -- incidents in last 30 days
    alert_count_30d     INTEGER           DEFAULT 0                  NOT NULL,
    last_incident_at    TIMESTAMPTZ,
    risk_factors        JSONB,                                                   -- e.g. {"crowd_density":"high","visibility":"low"}
    notes               TEXT,
    assessed_by         UUID,
    assessed_at         TIMESTAMPTZ       DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    next_review_at      TIMESTAMPTZ       GENERATED ALWAYS AS (
                                              assessed_at + INTERVAL '30 days'
                                          ) STORED,
    updated_at          TIMESTAMPTZ       DEFAULT CURRENT_TIMESTAMP  NOT NULL,

    CONSTRAINT pk_zone_risk_profile PRIMARY KEY (profile_id),
    CONSTRAINT uq_zone_risk         UNIQUE (zone_id),                           -- 1:1 with zone
    CONSTRAINT fk_zrp_zone          FOREIGN KEY (zone_id)     REFERENCES dsis.surveillance_zones(zone_id) ON DELETE CASCADE,
    CONSTRAINT fk_zrp_assessed_by   FOREIGN KEY (assessed_by) REFERENCES dsis.users(user_id)             ON DELETE SET NULL,
    CONSTRAINT chk_risk_score       CHECK (risk_score BETWEEN 0.0 AND 100.0),
    CONSTRAINT chk_incident_count   CHECK (incident_count_30d >= 0),
    CONSTRAINT chk_alert_count      CHECK (alert_count_30d >= 0)
);

CREATE TRIGGER trg_zrp_updated_at
    BEFORE UPDATE ON dsis.zone_risk_profile
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

COMMENT ON TABLE  dsis.zone_risk_profile               IS '1:1 extension of surveillance_zones. Stores dynamic risk scoring updated after each incident.';
COMMENT ON COLUMN dsis.zone_risk_profile.risk_factors   IS 'JSONB map of qualitative risk factors. Flexible to accommodate different zone types.';
COMMENT ON COLUMN dsis.zone_risk_profile.next_review_at IS 'Auto-computed: 30 days after last assessment. Used by the analytics engine.';

INSERT INTO dsis.zone_risk_profile (zone_id, risk_level, risk_score, incident_count_30d, alert_count_30d, risk_factors, assessed_by)
SELECT z.zone_id,
       CASE z.zone_code
           WHEN 'ZONE-ALPHA'   THEN 'low'::dsis.risk_level_t
           WHEN 'ZONE-BRAVO'   THEN 'moderate'::dsis.risk_level_t
           WHEN 'ZONE-CHARLIE' THEN 'critical'::dsis.risk_level_t
           WHEN 'ZONE-DELTA'   THEN 'high'::dsis.risk_level_t
           WHEN 'ZONE-ECHO'    THEN 'high'::dsis.risk_level_t
       END,
       CASE z.zone_code
           WHEN 'ZONE-ALPHA'   THEN 12.50
           WHEN 'ZONE-BRAVO'   THEN 34.75
           WHEN 'ZONE-CHARLIE' THEN 87.20
           WHEN 'ZONE-DELTA'   THEN 62.40
           WHEN 'ZONE-ECHO'    THEN 71.80
       END,
       CASE z.zone_code
           WHEN 'ZONE-ALPHA'   THEN 0 WHEN 'ZONE-BRAVO' THEN 2
           WHEN 'ZONE-CHARLIE' THEN 7 WHEN 'ZONE-DELTA' THEN 4 WHEN 'ZONE-ECHO' THEN 5 END,
       CASE z.zone_code
           WHEN 'ZONE-ALPHA'   THEN 1 WHEN 'ZONE-BRAVO' THEN 5
           WHEN 'ZONE-CHARLIE' THEN 21 WHEN 'ZONE-DELTA' THEN 11 WHEN 'ZONE-ECHO' THEN 14 END,
       '{"crowd_density":"variable","visibility":"good","history":"available"}'::jsonb,
       (SELECT user_id FROM dsis.users WHERE username = 'analyst_zara')
FROM dsis.surveillance_zones z;

-- -----------------------------------------------------------------
-- 5.3 drone_zone_assignments  (M:N: a drone can be assigned to many zones)
-- -----------------------------------------------------------------
CREATE TABLE dsis.drone_zone_assignments (
    assignment_id  UUID          DEFAULT uuid_generate_v4() NOT NULL,
    drone_id       UUID                                      NOT NULL,
    zone_id        UUID                                      NOT NULL,
    assigned_by    UUID,
    assigned_at    TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    unassigned_at  TIMESTAMPTZ,                                           -- NULL = currently assigned
    notes          TEXT,

    CONSTRAINT pk_drone_zone_assignments PRIMARY KEY (assignment_id),
    CONSTRAINT uq_dza_active             UNIQUE (drone_id, zone_id, unassigned_at),
    CONSTRAINT fk_dza_drone              FOREIGN KEY (drone_id)    REFERENCES dsis.drones(drone_id)              ON DELETE CASCADE,
    CONSTRAINT fk_dza_zone               FOREIGN KEY (zone_id)     REFERENCES dsis.surveillance_zones(zone_id)   ON DELETE CASCADE,
    CONSTRAINT fk_dza_assigned_by        FOREIGN KEY (assigned_by) REFERENCES dsis.users(user_id)                ON DELETE SET NULL
);

COMMENT ON TABLE dsis.drone_zone_assignments IS 'M:N assignment table linking drones to their designated surveillance zones with history tracking.';

INSERT INTO dsis.drone_zone_assignments (drone_id, zone_id, assigned_by)
SELECT d.drone_id, z.zone_id, (SELECT user_id FROM dsis.users WHERE username = 'admin_saim')
FROM dsis.drones d, dsis.surveillance_zones z
WHERE (d.serial_number = 'SN-DJI-M30T-001'    AND z.zone_code = 'ZONE-ALPHA')
   OR (d.serial_number = 'SN-DJI-M30T-001'    AND z.zone_code = 'ZONE-CHARLIE')
   OR (d.serial_number = 'SN-AUTEL-EVO2-002'  AND z.zone_code = 'ZONE-BRAVO')
   OR (d.serial_number = 'SN-SKYDIO-X10-003'  AND z.zone_code = 'ZONE-DELTA')
   OR (d.serial_number = 'SN-WINGTRA-FW-005'  AND z.zone_code = 'ZONE-ECHO');

-- ============================================================================================================================
-- SECTION 6: FLIGHT MISSIONS & LOGS
-- Tables: flight_missions, flight_logs, live_location_tracking
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 6.1 flight_missions
-- -----------------------------------------------------------------
CREATE TABLE dsis.flight_missions (
    mission_id          UUID                  DEFAULT uuid_generate_v4() NOT NULL,
    mission_ref         VARCHAR(20)           DEFAULT dsis.fn_generate_ref('MSN') NOT NULL,
    drone_id            UUID                                               NOT NULL,
    zone_id             UUID                                               NOT NULL,
    operator_id         UUID                                               NOT NULL,   -- user who launched mission
    supervisor_id       UUID,                                                           -- optional supervising admin
    mission_type        dsis.mission_type_t                                NOT NULL,
    status              dsis.mission_status_t DEFAULT 'planned'            NOT NULL,
    priority            SMALLINT              DEFAULT 3                    NOT NULL,   -- 1 (critical) to 5 (routine)
    briefing_notes      TEXT,
    planned_start_at    TIMESTAMPTZ                                        NOT NULL,
    planned_end_at      TIMESTAMPTZ,
    actual_start_at     TIMESTAMPTZ,
    actual_end_at       TIMESTAMPTZ,
    planned_altitude_m  SMALLINT,
    actual_altitude_m   SMALLINT,
    planned_path        JSONB,                                                          -- array of waypoints [{lat, lon, alt}]
    abort_reason        TEXT,
    weather_snapshot_id UUID,                                                           -- FK added after weather table
    created_at          TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP    NOT NULL,
    updated_at          TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP    NOT NULL,

    CONSTRAINT pk_flight_missions       PRIMARY KEY (mission_id),
    CONSTRAINT uq_mission_ref           UNIQUE (mission_ref),
    CONSTRAINT fk_fm_drone              FOREIGN KEY (drone_id)     REFERENCES dsis.drones(drone_id)              ON DELETE RESTRICT,
    CONSTRAINT fk_fm_zone               FOREIGN KEY (zone_id)      REFERENCES dsis.surveillance_zones(zone_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_fm_operator           FOREIGN KEY (operator_id)  REFERENCES dsis.users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT fk_fm_supervisor         FOREIGN KEY (supervisor_id)REFERENCES dsis.users(user_id)                ON DELETE SET NULL,
    CONSTRAINT chk_mission_priority     CHECK (priority BETWEEN 1 AND 5),
    CONSTRAINT chk_mission_dates        CHECK (planned_end_at IS NULL OR planned_end_at > planned_start_at),
    CONSTRAINT chk_actual_dates         CHECK (actual_end_at  IS NULL OR actual_end_at  > actual_start_at)
);

CREATE TRIGGER trg_fm_updated_at
    BEFORE UPDATE ON dsis.flight_missions
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

CREATE INDEX idx_fm_drone_id    ON dsis.flight_missions (drone_id, status);
CREATE INDEX idx_fm_zone_id     ON dsis.flight_missions (zone_id,  status);
CREATE INDEX idx_fm_operator    ON dsis.flight_missions (operator_id);
CREATE INDEX idx_fm_planned     ON dsis.flight_missions (planned_start_at DESC);
CREATE INDEX idx_fm_status      ON dsis.flight_missions (status) WHERE status IN ('planned','in_progress');

COMMENT ON TABLE  dsis.flight_missions            IS 'Individual drone mission records from planning through execution and completion.';
COMMENT ON COLUMN dsis.flight_missions.priority   IS '1 = critical immediate response; 5 = low-priority routine. Affects scheduling.';
COMMENT ON COLUMN dsis.flight_missions.planned_path IS 'JSONB array of waypoints: [{"lat":33.72,"lon":73.09,"alt_m":50,"action":"hover"}]';

INSERT INTO dsis.flight_missions (drone_id, zone_id, operator_id, mission_type, status, priority,
                                   planned_start_at, planned_end_at, planned_altitude_m, briefing_notes)
VALUES
    ((SELECT drone_id FROM dsis.drones WHERE serial_number = 'SN-DJI-M30T-001'),
     (SELECT zone_id  FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-ALPHA'),
     (SELECT user_id  FROM dsis.users WHERE username = 'op_ali'),
     'routine_patrol', 'completed', 4,
     CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '1 hour',
     80, 'Standard north campus patrol — check perimeter fencing and parking areas'),

    ((SELECT drone_id FROM dsis.drones WHERE serial_number = 'SN-SKYDIO-X10-003'),
     (SELECT zone_id  FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-DELTA'),
     (SELECT user_id  FROM dsis.users WHERE username = 'op_ali'),
     'incident_response', 'completed', 1,
     CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '45 minutes',
     100, 'Rapid deployment — suspicious vehicle reported near east gate'),

    ((SELECT drone_id FROM dsis.drones WHERE serial_number = 'SN-WINGTRA-FW-005'),
     (SELECT zone_id  FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-ECHO'),
     (SELECT user_id  FROM dsis.users WHERE username = 'op_ali'),
     'perimeter_check', 'in_progress', 3,
     CURRENT_TIMESTAMP - INTERVAL '30 minutes', CURRENT_TIMESTAMP + INTERVAL '1 hour',
     200, 'Maritime perimeter sweep — standard coastal surveillance protocol');

-- -----------------------------------------------------------------
-- 6.2 flight_logs  (high-frequency telemetry — partitioned by month)
-- -----------------------------------------------------------------
CREATE TABLE dsis.flight_logs (
    log_id          UUID               DEFAULT uuid_generate_v4() NOT NULL,
    mission_id      UUID                                           NOT NULL,
    drone_id        UUID                                           NOT NULL,
    log_sequence    INTEGER                                        NOT NULL,   -- ordered packet seq within mission
    latitude        NUMERIC(10, 7)                                 NOT NULL,
    longitude       NUMERIC(10, 7)                                 NOT NULL,
    altitude_m      NUMERIC(8, 2)                                  NOT NULL,
    heading_deg     NUMERIC(5, 2),                                             -- 0.00–360.00
    speed_kmh       NUMERIC(6, 2),
    battery_pct     SMALLINT,
    signal_rssi     SMALLINT,                                                  -- dBm signal strength
    temperature_c   NUMERIC(5, 2),                                             -- ambient temperature
    wind_speed_ms   NUMERIC(5, 2),                                             -- wind speed at altitude
    event_tag       VARCHAR(40),                                               -- e.g. 'waypoint_reached', 'hover_start'
    raw_telemetry   JSONB,                                                     -- full raw packet from drone SDK
    logged_at       TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,

    CONSTRAINT pk_flight_logs     PRIMARY KEY (log_id, logged_at),
    CONSTRAINT fk_fl_mission      FOREIGN KEY (mission_id) REFERENCES dsis.flight_missions(mission_id) ON DELETE CASCADE,
    CONSTRAINT fk_fl_drone        FOREIGN KEY (drone_id)   REFERENCES dsis.drones(drone_id)            ON DELETE CASCADE,
    CONSTRAINT chk_fl_battery     CHECK (battery_pct  BETWEEN 0 AND 100),
    CONSTRAINT chk_fl_heading     CHECK (heading_deg  BETWEEN 0 AND 360),
    CONSTRAINT chk_fl_altitude    CHECK (altitude_m   >= 0),
    CONSTRAINT chk_fl_lat         CHECK (latitude     BETWEEN -90  AND 90),
    CONSTRAINT chk_fl_lon         CHECK (longitude    BETWEEN -180 AND 180)
) PARTITION BY RANGE (logged_at);

-- Monthly partitions (current quarter + one quarter ahead)
CREATE TABLE dsis.flight_logs_2025_01 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE dsis.flight_logs_2025_02 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE dsis.flight_logs_2025_03 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE dsis.flight_logs_2025_04 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE dsis.flight_logs_2025_05 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE dsis.flight_logs_2025_06 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE dsis.flight_logs_2025_07 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE dsis.flight_logs_2025_08 PARTITION OF dsis.flight_logs
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE dsis.flight_logs_default PARTITION OF dsis.flight_logs DEFAULT;

CREATE INDEX idx_fl_mission_id  ON dsis.flight_logs (mission_id, log_sequence);
CREATE INDEX idx_fl_drone_time  ON dsis.flight_logs (drone_id, logged_at DESC);
CREATE INDEX idx_fl_geo         ON dsis.flight_logs (latitude, longitude);

COMMENT ON TABLE  dsis.flight_logs           IS 'High-frequency drone telemetry log. Range-partitioned by month for query performance at scale.';
COMMENT ON COLUMN dsis.flight_logs.log_sequence IS 'Sequential packet counter within a mission. Enables gap detection and ordering.';
COMMENT ON COLUMN dsis.flight_logs.raw_telemetry IS 'Full unprocessed telemetry packet. Preserved for post-mission forensic replay.';

-- -----------------------------------------------------------------
-- 6.3 live_location_tracking  (latest position only — not historical)
-- -----------------------------------------------------------------
CREATE TABLE dsis.live_location_tracking (
    tracking_id    UUID               DEFAULT uuid_generate_v4() NOT NULL,
    drone_id       UUID                                           NOT NULL,
    mission_id     UUID,
    latitude       NUMERIC(10, 7)                                 NOT NULL,
    longitude      NUMERIC(10, 7)                                 NOT NULL,
    altitude_m     NUMERIC(8, 2),
    heading_deg    NUMERIC(5, 2),
    speed_kmh      NUMERIC(6, 2),
    battery_pct    SMALLINT,
    is_online      BOOLEAN            DEFAULT TRUE                NOT NULL,
    updated_at     TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP   NOT NULL,

    CONSTRAINT pk_live_tracking     PRIMARY KEY (tracking_id),
    CONSTRAINT uq_live_drone        UNIQUE (drone_id),                         -- one live record per drone
    CONSTRAINT fk_lt_drone          FOREIGN KEY (drone_id)   REFERENCES dsis.drones(drone_id)          ON DELETE CASCADE,
    CONSTRAINT fk_lt_mission        FOREIGN KEY (mission_id) REFERENCES dsis.flight_missions(mission_id) ON DELETE SET NULL,
    CONSTRAINT chk_lt_battery       CHECK (battery_pct BETWEEN 0 AND 100),
    CONSTRAINT chk_lt_lat           CHECK (latitude    BETWEEN -90  AND 90),
    CONSTRAINT chk_lt_lon           CHECK (longitude   BETWEEN -180 AND 180)
);

COMMENT ON TABLE dsis.live_location_tracking IS 'Single-row-per-drone live position table. Updated by telemetry ingest. Use UPSERT (INSERT ... ON CONFLICT) for updates.';

-- ============================================================================================================================
-- SECTION 7: WEATHER DATA
-- ============================================================================================================================

CREATE TABLE dsis.weather_data (
    weather_id          UUID                    DEFAULT uuid_generate_v4() NOT NULL,
    zone_id             UUID                                                NOT NULL,
    condition           dsis.weather_condition_t                            NOT NULL,
    temperature_c       NUMERIC(5, 2),
    humidity_pct        SMALLINT,
    wind_speed_ms       NUMERIC(5, 2),
    wind_direction_deg  SMALLINT,
    visibility_km       NUMERIC(5, 2),
    pressure_hpa        NUMERIC(7, 2),
    cloud_cover_pct     SMALLINT,
    precipitation_mm    NUMERIC(5, 2),
    flight_clearance    dsis.flight_clearance_t NOT NULL,
    clearance_reason    TEXT,                                               -- explanation if not approved
    data_source         VARCHAR(60)             DEFAULT 'automatic_station' NOT NULL,
    recorded_at         TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP   NOT NULL,

    CONSTRAINT pk_weather_data        PRIMARY KEY (weather_id),
    CONSTRAINT fk_wd_zone             FOREIGN KEY (zone_id) REFERENCES dsis.surveillance_zones(zone_id) ON DELETE CASCADE,
    CONSTRAINT chk_humidity           CHECK (humidity_pct     BETWEEN 0 AND 100),
    CONSTRAINT chk_cloud_cover        CHECK (cloud_cover_pct  BETWEEN 0 AND 100),
    CONSTRAINT chk_wind_direction     CHECK (wind_direction_deg BETWEEN 0 AND 360),
    CONSTRAINT chk_precipitation      CHECK (precipitation_mm >= 0)
);

CREATE INDEX idx_wd_zone_time  ON dsis.weather_data (zone_id, recorded_at DESC);
CREATE INDEX idx_wd_clearance  ON dsis.weather_data (flight_clearance, recorded_at DESC);

COMMENT ON TABLE  dsis.weather_data                IS 'Environmental conditions per zone. Drives flight clearance decisions and mission planning.';
COMMENT ON COLUMN dsis.weather_data.flight_clearance IS 'Computed clearance status. Grounded = no flights permitted. Marginal = proceed with caution.';

-- Seed current weather per zone
INSERT INTO dsis.weather_data (zone_id, condition, temperature_c, humidity_pct, wind_speed_ms,
                                 wind_direction_deg, visibility_km, pressure_hpa, cloud_cover_pct,
                                 precipitation_mm, flight_clearance, data_source)
SELECT z.zone_id,
       'partly_cloudy'::dsis.weather_condition_t,
       28.5, 55, 4.2, 270, 12.0, 1013.25, 40, 0.0,
       'approved'::dsis.flight_clearance_t,
       'METAR_AUTO'
FROM dsis.surveillance_zones z;

-- Add FK from flight_missions to weather_data
ALTER TABLE dsis.flight_missions
    ADD CONSTRAINT fk_fm_weather FOREIGN KEY (weather_snapshot_id)
        REFERENCES dsis.weather_data(weather_id) ON DELETE SET NULL;

-- ============================================================================================================================
-- SECTION 8: DETECTION & OBJECT CLASSIFICATION
-- Tables: object_categories, detected_objects (partitioned)
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 8.1 object_categories
-- -----------------------------------------------------------------
CREATE TABLE dsis.object_categories (
    category_id       UUID                     DEFAULT uuid_generate_v4() NOT NULL,
    category_name     dsis.object_category_t                              NOT NULL,
    sub_category      VARCHAR(60),                                                   -- e.g. 'sedan', 'pickup_truck'
    default_threat    dsis.threat_level_t      DEFAULT 'low'              NOT NULL,
    description       TEXT,
    detection_keywords TEXT[],                                                        -- AI model label matching hints
    is_active         BOOLEAN                  DEFAULT TRUE                NOT NULL,

    CONSTRAINT pk_object_categories       PRIMARY KEY (category_id),
    CONSTRAINT uq_category_sub            UNIQUE (category_name, sub_category)
);

COMMENT ON TABLE  dsis.object_categories             IS 'Taxonomy of detectable object types with default threat classifications.';
COMMENT ON COLUMN dsis.object_categories.detection_keywords IS 'Array of AI model output labels that map to this category. Used during auto-classification.';

INSERT INTO dsis.object_categories (category_name, sub_category, default_threat, description, detection_keywords) VALUES
    ('person',   'civilian',          'none',     'Civilian pedestrian',                  ARRAY['person','pedestrian','human']),
    ('person',   'armed_individual',  'critical', 'Person carrying visible weapon',        ARRAY['armed','weapon_carrier','gunman']),
    ('person',   'crowd',             'medium',   'Group of 5+ individuals',               ARRAY['crowd','group','gathering']),
    ('vehicle',  'sedan',             'low',      'Standard passenger car',                ARRAY['car','sedan','vehicle']),
    ('vehicle',  'pickup_truck',      'medium',   'Pickup or utility vehicle',             ARRAY['pickup','truck','ute']),
    ('vehicle',  'military_vehicle',  'critical', 'Armoured or military-marked vehicle',   ARRAY['armoured','military','tank']),
    ('weapon',   'firearm',           'critical', 'Detected firearm or rifle',             ARRAY['gun','rifle','firearm','weapon']),
    ('aircraft', 'unauthorized_uav',  'high',     'Unknown or unauthorized drone',         ARRAY['uav','drone','quadcopter','fixed_wing']),
    ('package',  'unattended_object', 'high',     'Unattended bag, box, or package',       ARRAY['bag','package','box','luggage']),
    ('animal',   'wildlife',          'low',      'Animal detected in surveillance zone',  ARRAY['animal','dog','wildlife']);

-- -----------------------------------------------------------------
-- 8.2 detected_objects  (core detection table — partitioned by month)
-- -----------------------------------------------------------------
CREATE TABLE dsis.detected_objects (
    detection_id       UUID                  DEFAULT uuid_generate_v4() NOT NULL,
    mission_id         UUID                                               NOT NULL,
    drone_id           UUID                                               NOT NULL,
    zone_id            UUID                                               NOT NULL,
    category_id        UUID                                               NOT NULL,
    threat_level       dsis.threat_level_t                                NOT NULL,
    movement_type      dsis.movement_t       DEFAULT 'unknown'            NOT NULL,
    confidence_score   NUMERIC(5, 4),                                              -- 0.0000–1.0000 AI confidence
    latitude           NUMERIC(10, 7)                                     NOT NULL,
    longitude          NUMERIC(10, 7)                                     NOT NULL,
    altitude_m         NUMERIC(8, 2),
    bounding_box       JSONB,                                                       -- {x,y,width,height} in frame pixels
    object_count       SMALLINT              DEFAULT 1                    NOT NULL,  -- for crowds or vehicle convoys
    image_snapshot_url TEXT,                                                         -- S3 / storage URL
    video_clip_url     TEXT,
    ai_raw_labels      JSONB,                                                        -- raw output from detection model
    notes              TEXT,
    is_confirmed       BOOLEAN               DEFAULT FALSE                NOT NULL,  -- confirmed by human analyst
    confirmed_by       UUID,
    confirmed_at       TIMESTAMPTZ,
    detected_at        TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP    NOT NULL,

    CONSTRAINT pk_detected_objects      PRIMARY KEY (detection_id, detected_at),
    CONSTRAINT fk_do_mission            FOREIGN KEY (mission_id)    REFERENCES dsis.flight_missions(mission_id)  ON DELETE RESTRICT,
    CONSTRAINT fk_do_drone              FOREIGN KEY (drone_id)      REFERENCES dsis.drones(drone_id)             ON DELETE RESTRICT,
    CONSTRAINT fk_do_zone               FOREIGN KEY (zone_id)       REFERENCES dsis.surveillance_zones(zone_id)  ON DELETE RESTRICT,
    CONSTRAINT fk_do_category           FOREIGN KEY (category_id)   REFERENCES dsis.object_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_do_confirmed_by       FOREIGN KEY (confirmed_by)  REFERENCES dsis.users(user_id)               ON DELETE SET NULL,
    CONSTRAINT chk_confidence           CHECK (confidence_score BETWEEN 0 AND 1),
    CONSTRAINT chk_object_count         CHECK (object_count >= 1),
    CONSTRAINT chk_do_lat               CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT chk_do_lon               CHECK (longitude BETWEEN -180 AND 180)
) PARTITION BY RANGE (detected_at);

-- Monthly partitions
CREATE TABLE dsis.detected_objects_2025_01 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE dsis.detected_objects_2025_02 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE dsis.detected_objects_2025_03 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE dsis.detected_objects_2025_04 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE dsis.detected_objects_2025_05 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE dsis.detected_objects_2025_06 PARTITION OF dsis.detected_objects FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE dsis.detected_objects_default PARTITION OF dsis.detected_objects DEFAULT;

CREATE INDEX idx_do_mission_id     ON dsis.detected_objects (mission_id, detected_at DESC);
CREATE INDEX idx_do_zone_threat    ON dsis.detected_objects (zone_id, threat_level, detected_at DESC);
CREATE INDEX idx_do_drone_time     ON dsis.detected_objects (drone_id, detected_at DESC);
CREATE INDEX idx_do_category       ON dsis.detected_objects (category_id, threat_level);
CREATE INDEX idx_do_unconfirmed    ON dsis.detected_objects (zone_id, detected_at) WHERE is_confirmed = FALSE;
CREATE INDEX idx_do_geo            ON dsis.detected_objects (latitude, longitude);

COMMENT ON TABLE  dsis.detected_objects              IS 'Core detection records. Range-partitioned by month. Every AI detection or manual log entry is stored here.';
COMMENT ON COLUMN dsis.detected_objects.confidence_score IS 'AI model confidence 0.0 (uncertain) to 1.0 (certain). Detections below 0.60 may be flagged for review.';
COMMENT ON COLUMN dsis.detected_objects.bounding_box     IS 'Pixel coordinates in the original video frame. Used for UI overlay rendering.';

-- Seed sample detections
INSERT INTO dsis.detected_objects (mission_id, drone_id, zone_id, category_id, threat_level,
                                    movement_type, confidence_score, latitude, longitude,
                                    altitude_m, object_count, detected_at)
SELECT
    fm.mission_id,
    fm.drone_id,
    fm.zone_id,
    oc.category_id,
    CASE oc.sub_category
        WHEN 'civilian'         THEN 'none'::dsis.threat_level_t
        WHEN 'sedan'            THEN 'low'::dsis.threat_level_t
        WHEN 'unauthorized_uav' THEN 'high'::dsis.threat_level_t
    END,
    CASE oc.sub_category
        WHEN 'civilian' THEN 'walking'::dsis.movement_t
        WHEN 'sedan'    THEN 'driving'::dsis.movement_t
        ELSE 'flying'::dsis.movement_t
    END,
    CASE oc.sub_category WHEN 'civilian' THEN 0.9421 WHEN 'sedan' THEN 0.8873 ELSE 0.7701 END,
    33.7295 + (random() * 0.01), 73.0931 + (random() * 0.01),
    80.0, 1,
    CURRENT_TIMESTAMP - INTERVAL '3 days'
FROM
    (SELECT mission_id, drone_id, zone_id FROM dsis.flight_missions LIMIT 1) fm,
    (SELECT category_id, sub_category FROM dsis.object_categories
     WHERE sub_category IN ('civilian','sedan','unauthorized_uav')) oc;

-- ============================================================================================================================
-- SECTION 9: ALERTS
-- Tables: alerts, alert_escalation_log
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 9.1 alerts
-- -----------------------------------------------------------------
CREATE TABLE dsis.alerts (
    alert_id         UUID                   DEFAULT uuid_generate_v4() NOT NULL,
    alert_ref        VARCHAR(20)            DEFAULT dsis.fn_generate_ref('ALR') NOT NULL,
    detection_id     UUID,                                                           -- nullable: alert may be manual
    zone_id          UUID                                                NOT NULL,
    drone_id         UUID,
    mission_id       UUID,
    severity         dsis.alert_severity_t                               NOT NULL,
    status           dsis.alert_status_t    DEFAULT 'open'              NOT NULL,
    title            VARCHAR(200)                                        NOT NULL,
    description      TEXT,
    auto_generated   BOOLEAN                DEFAULT TRUE                 NOT NULL,  -- TRUE = trigger-generated
    assigned_to      UUID,
    acknowledged_by  UUID,
    acknowledged_at  TIMESTAMPTZ,
    resolved_by      UUID,
    resolved_at      TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at       TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP    NOT NULL,
    updated_at       TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP    NOT NULL,

    CONSTRAINT pk_alerts            PRIMARY KEY (alert_id),
    CONSTRAINT uq_alert_ref         UNIQUE (alert_ref),
    CONSTRAINT fk_alerts_zone       FOREIGN KEY (zone_id)         REFERENCES dsis.surveillance_zones(zone_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_alerts_drone      FOREIGN KEY (drone_id)        REFERENCES dsis.drones(drone_id)              ON DELETE SET NULL,
    CONSTRAINT fk_alerts_mission    FOREIGN KEY (mission_id)      REFERENCES dsis.flight_missions(mission_id)   ON DELETE SET NULL,
    CONSTRAINT fk_alerts_assigned   FOREIGN KEY (assigned_to)     REFERENCES dsis.users(user_id)                ON DELETE SET NULL,
    CONSTRAINT fk_alerts_ack        FOREIGN KEY (acknowledged_by) REFERENCES dsis.users(user_id)                ON DELETE SET NULL,
    CONSTRAINT fk_alerts_resolved   FOREIGN KEY (resolved_by)     REFERENCES dsis.users(user_id)                ON DELETE SET NULL
);

CREATE TRIGGER trg_alerts_updated_at
    BEFORE UPDATE ON dsis.alerts
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

CREATE INDEX idx_alerts_zone_sev    ON dsis.alerts (zone_id, severity, status);
CREATE INDEX idx_alerts_open        ON dsis.alerts (severity, created_at DESC) WHERE status = 'open';
CREATE INDEX idx_alerts_assigned    ON dsis.alerts (assigned_to) WHERE status NOT IN ('resolved','false_positive');
CREATE INDEX idx_alerts_created     ON dsis.alerts (created_at DESC);

COMMENT ON TABLE  dsis.alerts               IS 'Security and operational alerts. Can be auto-generated by triggers or manually raised.';
COMMENT ON COLUMN dsis.alerts.auto_generated IS 'TRUE when created by the fn_trigger_auto_alert trigger. FALSE when raised manually by an operator or analyst.';

-- Seed initial alerts
INSERT INTO dsis.alerts (zone_id, drone_id, mission_id, severity, status, title, description, auto_generated)
SELECT
    z.zone_id,
    d.drone_id,
    fm.mission_id,
    'high'::dsis.alert_severity_t,
    'open'::dsis.alert_status_t,
    'Unauthorized UAV Detected — Zone DELTA',
    'An unidentified drone with no transponder signal was detected flying within the restricted corridor at ~100m altitude. Confidence: 77%. Immediate investigation required.',
    TRUE
FROM dsis.surveillance_zones z, dsis.drones d, dsis.flight_missions fm
WHERE z.zone_code = 'ZONE-DELTA'
  AND d.serial_number = 'SN-SKYDIO-X10-003'
  AND fm.mission_type = 'incident_response'
LIMIT 1;

INSERT INTO dsis.alerts (zone_id, severity, status, title, description, auto_generated)
SELECT zone_id, 'medium'::dsis.alert_severity_t, 'acknowledged'::dsis.alert_status_t,
       'Large Crowd Assembly — Zone BRAVO',
       'Crowd of approximately 40+ individuals detected near the industrial access gate. Pattern analysis indicates non-routine gathering.',
       FALSE
FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-BRAVO';

-- -----------------------------------------------------------------
-- 9.2 alert_escalation_log
-- -----------------------------------------------------------------
CREATE TABLE dsis.alert_escalation_log (
    escalation_id    UUID                      DEFAULT uuid_generate_v4() NOT NULL,
    alert_id         UUID                                                   NOT NULL,
    action_taken     dsis.escalation_action_t                               NOT NULL,
    performed_by     UUID                                                   NOT NULL,
    previous_status  dsis.alert_status_t,
    new_status       dsis.alert_status_t,
    escalated_to     UUID,                                                            -- user it was escalated to
    notes            TEXT,
    performed_at     TIMESTAMPTZ               DEFAULT CURRENT_TIMESTAMP    NOT NULL,

    CONSTRAINT pk_alert_escalation   PRIMARY KEY (escalation_id),
    CONSTRAINT fk_aes_alert          FOREIGN KEY (alert_id)      REFERENCES dsis.alerts(alert_id)       ON DELETE CASCADE,
    CONSTRAINT fk_aes_performer      FOREIGN KEY (performed_by)  REFERENCES dsis.users(user_id)         ON DELETE RESTRICT,
    CONSTRAINT fk_aes_escalated_to   FOREIGN KEY (escalated_to)  REFERENCES dsis.users(user_id)         ON DELETE SET NULL
);

CREATE INDEX idx_aes_alert_id  ON dsis.alert_escalation_log (alert_id, performed_at DESC);

COMMENT ON TABLE dsis.alert_escalation_log IS 'Full history of every status change and escalation action on every alert. Immutable audit trail.';

-- ============================================================================================================================
-- SECTION 10: INCIDENT MANAGEMENT
-- Tables: incident_reports, evidence_storage, video_metadata
-- ============================================================================================================================

-- -----------------------------------------------------------------
-- 10.1 incident_reports
-- -----------------------------------------------------------------
CREATE TABLE dsis.incident_reports (
    incident_id      UUID                   DEFAULT uuid_generate_v4() NOT NULL,
    incident_ref     VARCHAR(20)            DEFAULT dsis.fn_generate_ref('INC') NOT NULL,
    alert_id         UUID,                                                            -- originating alert (nullable)
    zone_id          UUID                                               NOT NULL,
    reported_by      UUID                                               NOT NULL,
    assigned_to      UUID,
    status           dsis.incident_status_t DEFAULT 'open'             NOT NULL,
    title            VARCHAR(250)                                       NOT NULL,
    description      TEXT                                               NOT NULL,
    incident_lat     NUMERIC(10, 7),
    incident_lon     NUMERIC(10, 7),
    severity_rating  SMALLINT,                                                        -- 1 (minor) to 5 (catastrophic)
    response_notes   TEXT,
    resolution_notes TEXT,
    opened_at        TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    under_review_at  TIMESTAMPTZ,
    resolved_at      TIMESTAMPTZ,
    archived_at      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    updated_at       TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP  NOT NULL,

    CONSTRAINT pk_incident_reports    PRIMARY KEY (incident_id),
    CONSTRAINT uq_incident_ref        UNIQUE (incident_ref),
    CONSTRAINT fk_ir_alert            FOREIGN KEY (alert_id)    REFERENCES dsis.alerts(alert_id)              ON DELETE SET NULL,
    CONSTRAINT fk_ir_zone             FOREIGN KEY (zone_id)     REFERENCES dsis.surveillance_zones(zone_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_ir_reported_by      FOREIGN KEY (reported_by) REFERENCES dsis.users(user_id)                ON DELETE RESTRICT,
    CONSTRAINT fk_ir_assigned_to      FOREIGN KEY (assigned_to) REFERENCES dsis.users(user_id)                ON DELETE SET NULL,
    CONSTRAINT chk_severity_rating    CHECK (severity_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_ir_lat             CHECK (incident_lat BETWEEN -90  AND 90),
    CONSTRAINT chk_ir_lon             CHECK (incident_lon BETWEEN -180 AND 180)
);

CREATE TRIGGER trg_ir_updated_at
    BEFORE UPDATE ON dsis.incident_reports
    FOR EACH ROW EXECUTE FUNCTION dsis.fn_set_updated_at();

CREATE INDEX idx_ir_zone_status   ON dsis.incident_reports (zone_id, status);
CREATE INDEX idx_ir_assigned      ON dsis.incident_reports (assigned_to) WHERE status NOT IN ('resolved','archived');
CREATE INDEX idx_ir_opened        ON dsis.incident_reports (opened_at DESC);
CREATE INDEX idx_ir_alert         ON dsis.incident_reports (alert_id);

COMMENT ON TABLE  dsis.incident_reports             IS 'Formal incident records following alert escalation. Tracks full lifecycle from open to archived.';
COMMENT ON COLUMN dsis.incident_reports.severity_rating IS '1=minor, 2=moderate, 3=significant, 4=major, 5=catastrophic. Used in risk analytics.';

-- Seed a sample incident
INSERT INTO dsis.incident_reports (alert_id, zone_id, reported_by, assigned_to, status, title,
                                    description, severity_rating, incident_lat, incident_lon)
SELECT
    a.alert_id,
    a.zone_id,
    (SELECT user_id FROM dsis.users WHERE username = 'analyst_zara'),
    (SELECT user_id FROM dsis.users WHERE username = 'admin_saim'),
    'under_review'::dsis.incident_status_t,
    'INC-001: Unauthorized Drone Intrusion — East Corridor',
    'Following alert ALR detection, an unknown UAV was confirmed to have entered Zone DELTA airspace without authorization. Drone was not responding to standard identification protocols. Full forensic review initiated.',
    4,
    33.7295, 73.0931
FROM dsis.alerts a
WHERE a.title LIKE '%Unauthorized UAV%'
LIMIT 1;

-- -----------------------------------------------------------------
-- 10.2 evidence_storage
-- -----------------------------------------------------------------
CREATE TABLE dsis.evidence_storage (
    evidence_id       UUID                  DEFAULT uuid_generate_v4() NOT NULL,
    incident_id       UUID                                               NOT NULL,
    detection_id      UUID,
    evidence_type     dsis.evidence_type_t                               NOT NULL,
    file_name         VARCHAR(250)                                       NOT NULL,
    file_size_bytes   BIGINT,
    mime_type         VARCHAR(80),
    storage_path      TEXT                                               NOT NULL,  -- S3 URI or local path
    storage_tier      dsis.storage_tier_t   DEFAULT 'hot'               NOT NULL,
    checksum_sha256   VARCHAR(64),                                                  -- integrity verification hash
    is_encrypted      BOOLEAN               DEFAULT TRUE                 NOT NULL,
    encryption_key_id VARCHAR(80),                                                  -- KMS key reference
    collected_by      UUID,
    collected_at      TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP    NOT NULL,
    chain_of_custody  JSONB,                                                         -- [{user, action, timestamp}]
    retention_until   TIMESTAMPTZ,                                                   -- legal hold expiry

    CONSTRAINT pk_evidence_storage    PRIMARY KEY (evidence_id),
    CONSTRAINT fk_es_incident         FOREIGN KEY (incident_id)  REFERENCES dsis.incident_reports(incident_id) ON DELETE RESTRICT,
    CONSTRAINT fk_es_collected_by     FOREIGN KEY (collected_by) REFERENCES dsis.users(user_id)                ON DELETE SET NULL,
    CONSTRAINT chk_file_size          CHECK (file_size_bytes > 0)
);

CREATE INDEX idx_es_incident     ON dsis.evidence_storage (incident_id, evidence_type);
CREATE INDEX idx_es_storage_tier ON dsis.evidence_storage (storage_tier);

COMMENT ON TABLE  dsis.evidence_storage               IS 'Digital evidence metadata storage with chain-of-custody tracking. Files stored externally (S3/NAS).';
COMMENT ON COLUMN dsis.evidence_storage.chain_of_custody IS 'Immutable JSONB audit list. Each entry: {"user_id":"...","action":"viewed","ts":"2025-04-18T10:00:00Z"}';
COMMENT ON COLUMN dsis.evidence_storage.checksum_sha256  IS 'SHA-256 hash of the file at collection time. Used to detect tampering.';

-- -----------------------------------------------------------------
-- 10.3 video_metadata
-- -----------------------------------------------------------------
CREATE TABLE dsis.video_metadata (
    video_id          UUID          DEFAULT uuid_generate_v4() NOT NULL,
    mission_id        UUID                                      NOT NULL,
    drone_id          UUID                                      NOT NULL,
    evidence_id       UUID,                                                  -- links to evidence_storage if filed
    file_name         VARCHAR(250)                              NOT NULL,
    duration_seconds  INTEGER,
    resolution        VARCHAR(20),                                           -- e.g. '3840x2160'
    fps               SMALLINT,
    codec             VARCHAR(20),
    file_size_bytes   BIGINT,
    storage_path      TEXT                                      NOT NULL,
    thumbnail_url     TEXT,
    is_processed      BOOLEAN       DEFAULT FALSE               NOT NULL,   -- TRUE after AI analysis complete
    ai_analysis_json  JSONB,                                                 -- detection results from AI pipeline
    recorded_start_at TIMESTAMPTZ,
    recorded_end_at   TIMESTAMPTZ,
    uploaded_at       TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    uploaded_by       UUID,

    CONSTRAINT pk_video_metadata    PRIMARY KEY (video_id),
    CONSTRAINT fk_vm_mission        FOREIGN KEY (mission_id) REFERENCES dsis.flight_missions(mission_id) ON DELETE CASCADE,
    CONSTRAINT fk_vm_drone          FOREIGN KEY (drone_id)   REFERENCES dsis.drones(drone_id)            ON DELETE CASCADE,
    CONSTRAINT fk_vm_evidence       FOREIGN KEY (evidence_id)REFERENCES dsis.evidence_storage(evidence_id) ON DELETE SET NULL,
    CONSTRAINT fk_vm_uploaded_by    FOREIGN KEY (uploaded_by)REFERENCES dsis.users(user_id)              ON DELETE SET NULL,
    CONSTRAINT chk_duration         CHECK (duration_seconds >= 0),
    CONSTRAINT chk_fps              CHECK (fps > 0),
    CONSTRAINT chk_file_size_v      CHECK (file_size_bytes > 0)
);

CREATE INDEX idx_vm_mission    ON dsis.video_metadata (mission_id, recorded_start_at DESC);
CREATE INDEX idx_vm_unprocessed ON dsis.video_metadata (uploaded_at) WHERE is_processed = FALSE;

COMMENT ON TABLE  dsis.video_metadata             IS 'Metadata registry for video recordings per mission. AI analysis results stored in ai_analysis_json.';
COMMENT ON COLUMN dsis.video_metadata.ai_analysis_json IS 'Output of video intelligence pipeline: detected objects, timestamps, bounding boxes, confidence scores.';

-- ============================================================================================================================
-- SECTION 11: ANALYTICS & PREDICTIVE INTELLIGENCE
-- ============================================================================================================================

CREATE TABLE dsis.predictive_analytics_log (
    analytics_id      UUID                      DEFAULT uuid_generate_v4() NOT NULL,
    zone_id           UUID,
    model_type        dsis.prediction_model_t                               NOT NULL,
    model_version     VARCHAR(20)               DEFAULT '1.0'               NOT NULL,
    input_features    JSONB                                                  NOT NULL,  -- features fed to model
    prediction_output JSONB                                                  NOT NULL,  -- model output / probabilities
    prediction_label  VARCHAR(80),                                                      -- human-readable summary
    confidence        NUMERIC(5, 4),                                                    -- 0.0000–1.0000
    risk_score        NUMERIC(5, 2),                                                    -- 0.00–100.00 if applicable
    is_actioned       BOOLEAN                   DEFAULT FALSE               NOT NULL,   -- was output acted upon?
    actioned_by       UUID,
    action_notes      TEXT,
    computed_at       TIMESTAMPTZ               DEFAULT CURRENT_TIMESTAMP   NOT NULL,

    CONSTRAINT pk_analytics           PRIMARY KEY (analytics_id),
    CONSTRAINT fk_pa_zone             FOREIGN KEY (zone_id)      REFERENCES dsis.surveillance_zones(zone_id) ON DELETE SET NULL,
    CONSTRAINT fk_pa_actioned_by      FOREIGN KEY (actioned_by)  REFERENCES dsis.users(user_id)              ON DELETE SET NULL,
    CONSTRAINT chk_pa_confidence      CHECK (confidence  BETWEEN 0 AND 1),
    CONSTRAINT chk_pa_risk_score      CHECK (risk_score  BETWEEN 0 AND 100)
);

CREATE INDEX idx_pa_zone_model   ON dsis.predictive_analytics_log (zone_id, model_type, computed_at DESC);
CREATE INDEX idx_pa_unactioned   ON dsis.predictive_analytics_log (computed_at DESC) WHERE is_actioned = FALSE;

COMMENT ON TABLE  dsis.predictive_analytics_log         IS 'Outputs from ML/AI prediction models. Stores inputs, outputs, and human action tracking.';
COMMENT ON COLUMN dsis.predictive_analytics_log.model_type IS 'Identifies which model produced this output — threat_forecast, anomaly_detection, etc.';

-- Seed a sample prediction
INSERT INTO dsis.predictive_analytics_log (zone_id, model_type, model_version, input_features, prediction_output,
                                            prediction_label, confidence, risk_score)
SELECT
    zone_id,
    'threat_forecast'::dsis.prediction_model_t,
    '2.1',
    '{"incident_count_7d":3,"alert_count_7d":9,"avg_confidence":0.84,"zone_type":"border"}'::jsonb,
    '{"threat_probability":0.72,"predicted_class":"high","next_72h_incidents":2}'::jsonb,
    'High probability of security incident within 72 hours',
    0.7214, 72.14
FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-CHARLIE';

-- ============================================================================================================================
-- SECTION 12: AUDIT LOG (Partitioned — high volume)
-- ============================================================================================================================

CREATE TABLE dsis.audit_log (
    audit_id       UUID                  DEFAULT uuid_generate_v4() NOT NULL,
    user_id        UUID,                                                          -- NULL for system actions
    session_id     UUID,
    action         dsis.audit_action_t                               NOT NULL,
    table_name     VARCHAR(80),
    record_id      TEXT,                                                          -- PK of affected record (text for flexibility)
    old_values     JSONB,                                                         -- snapshot before change
    new_values     JSONB,                                                         -- snapshot after change
    ip_address     INET,
    user_agent     TEXT,
    query_hash     TEXT,                                                          -- hash of executed query (for dedup)
    status         VARCHAR(10)           DEFAULT 'success'           NOT NULL,   -- 'success' | 'denied' | 'error'
    error_message  TEXT,
    logged_at      TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP   NOT NULL,

    CONSTRAINT pk_audit_log       PRIMARY KEY (audit_id, logged_at),
    CONSTRAINT fk_al_user         FOREIGN KEY (user_id)    REFERENCES dsis.users(user_id)        ON DELETE SET NULL,
    CONSTRAINT fk_al_session      FOREIGN KEY (session_id) REFERENCES dsis.user_sessions(session_id) ON DELETE SET NULL,
    CONSTRAINT chk_al_status      CHECK (status IN ('success','denied','error'))
) PARTITION BY RANGE (logged_at);

-- Monthly partitions
CREATE TABLE dsis.audit_log_2025_01 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE dsis.audit_log_2025_02 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE dsis.audit_log_2025_03 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE dsis.audit_log_2025_04 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE dsis.audit_log_2025_05 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE dsis.audit_log_2025_06 PARTITION OF dsis.audit_log FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE dsis.audit_log_default PARTITION OF dsis.audit_log DEFAULT;

CREATE INDEX idx_al_user_time    ON dsis.audit_log (user_id, logged_at DESC);
CREATE INDEX idx_al_table        ON dsis.audit_log (table_name, logged_at DESC);
CREATE INDEX idx_al_action       ON dsis.audit_log (action, logged_at DESC);
CREATE INDEX idx_al_denied       ON dsis.audit_log (logged_at DESC) WHERE status = 'denied';

COMMENT ON TABLE  dsis.audit_log           IS 'System-wide immutable audit trail. Range-partitioned by month. Never DELETE from this table.';
COMMENT ON COLUMN dsis.audit_log.old_values IS 'Full row snapshot before UPDATE/DELETE. Enables point-in-time change tracking.';

-- ============================================================================================================================
-- SECTION 13: BACK-FILL DEFERRED FOREIGN KEYS
-- (FKs that reference tables created later in the script)
-- ============================================================================================================================

-- drone_status.active_mission_id → flight_missions
ALTER TABLE dsis.drone_status
    ADD CONSTRAINT fk_ds_active_mission
        FOREIGN KEY (active_mission_id)
        REFERENCES dsis.flight_missions(mission_id)
        ON DELETE SET NULL;

-- ============================================================================================================================
-- SECTION 14: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================================================================

-- Enable RLS on sensitive tables
ALTER TABLE dsis.users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE dsis.audit_log        ENABLE ROW LEVEL SECURITY;
ALTER TABLE dsis.evidence_storage ENABLE ROW LEVEL SECURITY;
ALTER TABLE dsis.incident_reports ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own row (unless admin)
-- In a real deployment, current_setting('app.current_user_id') is set by the backend on connection
CREATE POLICY pol_users_self_view ON dsis.users
    FOR SELECT
    USING (
        user_id = (SELECT user_id FROM dsis.users WHERE username = current_user)
        OR current_user IN ('dsis_admin', 'superadmin', 'postgres')
    );

-- Policy: only super_admin can read audit_log
CREATE POLICY pol_audit_admin_only ON dsis.audit_log
    FOR SELECT
    USING (current_user IN ('dsis_admin', 'superadmin', 'postgres'));

-- Policy: evidence visible only to assigned analyst or admin
CREATE POLICY pol_evidence_restricted ON dsis.evidence_storage
    FOR SELECT
    USING (current_user IN ('dsis_admin', 'superadmin', 'postgres'));

-- Policy: incident reports — assigned user or admin
CREATE POLICY pol_incidents_assigned ON dsis.incident_reports
    FOR SELECT
    USING (current_user IN ('dsis_admin', 'superadmin', 'postgres'));

COMMENT ON POLICY pol_audit_admin_only ON dsis.audit_log IS
    'Restricts audit log reads to superusers. Prevents self-covering by regular admins.';

-- ============================================================================================================================
-- SECTION 15: DATABASE ROLES & GRANTS
-- ============================================================================================================================

-- Create application-level DB roles (separate from application RBAC)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dsis_admin')  THEN CREATE ROLE dsis_admin  LOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dsis_operator') THEN CREATE ROLE dsis_operator LOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dsis_analyst')  THEN CREATE ROLE dsis_analyst  LOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dsis_viewer')   THEN CREATE ROLE dsis_viewer   LOGIN; END IF;
END $$;

-- dsis_admin: full access to all tables
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA dsis TO dsis_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dsis TO dsis_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA dsis TO dsis_admin;

-- dsis_operator: can read/write operational tables, cannot touch users or audit
GRANT SELECT, INSERT, UPDATE ON dsis.drones, dsis.drone_status, dsis.drone_health_log,
                                  dsis.flight_missions, dsis.flight_logs, dsis.live_location_tracking,
                                  dsis.detected_objects, dsis.alerts, dsis.weather_data    TO dsis_operator;
GRANT SELECT ON dsis.surveillance_zones, dsis.object_categories, dsis.roles               TO dsis_operator;

-- dsis_analyst: read detections, read/write alerts and incidents
GRANT SELECT ON dsis.drones, dsis.drone_status, dsis.flight_missions, dsis.flight_logs,
                dsis.detected_objects, dsis.weather_data, dsis.surveillance_zones           TO dsis_analyst;
GRANT SELECT, INSERT, UPDATE ON dsis.alerts, dsis.alert_escalation_log,
                                  dsis.incident_reports, dsis.evidence_storage,
                                  dsis.predictive_analytics_log                             TO dsis_analyst;

-- dsis_viewer: read-only on public-facing tables
GRANT SELECT ON dsis.drones, dsis.drone_status, dsis.surveillance_zones,
                dsis.flight_missions, dsis.alerts, dsis.incident_reports                    TO dsis_viewer;

COMMENT ON ROLE dsis_admin    IS 'Full database access for backend admin service.';
COMMENT ON ROLE dsis_operator IS 'Operational read/write — used by drone control application.';
COMMENT ON ROLE dsis_analyst  IS 'Intelligence analysis and incident management access.';
COMMENT ON ROLE dsis_viewer   IS 'Dashboard read-only access.';

-- ============================================================================================================================
-- SECTION 16: PERFORMANCE INDEXES — COMPOSITE & COVERING
-- (Additional advanced indexes beyond table-level definitions)
-- ============================================================================================================================

-- Composite: alerts by zone + severity + status (dashboard query)
CREATE INDEX idx_alerts_dashboard
    ON dsis.alerts (zone_id, severity DESC, status, created_at DESC)
    WHERE status IN ('open', 'acknowledged', 'escalated');

-- Partial: active drone assignments only
CREATE INDEX idx_dza_active_only
    ON dsis.drone_zone_assignments (drone_id, zone_id)
    WHERE unassigned_at IS NULL;

-- Trigram: full-text search on incident titles (supports LIKE '%keyword%')
CREATE INDEX idx_ir_title_trgm
    ON dsis.incident_reports USING GIN (title gin_trgm_ops);

-- Trigram: full-text search on alert titles
CREATE INDEX idx_alerts_title_trgm
    ON dsis.alerts USING GIN (title gin_trgm_ops);

-- Covering index: missions list API (avoids heap fetch for common columns)
CREATE INDEX idx_fm_covering
    ON dsis.flight_missions (zone_id, status, planned_start_at DESC)
    INCLUDE (drone_id, mission_type, operator_id);

-- JSONB: index on camera_specs for thermal-capable drone queries
CREATE INDEX idx_drones_thermal
    ON dsis.drones USING GIN (camera_specs);

-- BRIN: for time-series flight_logs (very large, sequential data)
CREATE INDEX idx_fl_logged_at_brin
    ON dsis.flight_logs_2025_04 USING BRIN (logged_at);

COMMENT ON INDEX dsis.idx_alerts_dashboard IS 'Covering index for the main dashboard alerts widget — avoids full table scan.';
COMMENT ON INDEX dsis.idx_ir_title_trgm    IS 'GIN trigram index enables fast ILIKE search on incident titles from the search bar.';

-- ============================================================================================================================
-- SECTION 17: ANALYTICAL VIEWS
-- (Materialized & regular views for reporting, dashboards, and API consumption)
-- ============================================================================================================================

-- View 1: Active fleet overview
CREATE OR REPLACE VIEW dsis.vw_active_fleet AS
SELECT
    d.drone_id,
    d.drone_ref,
    d.serial_number,
    d.model_name,
    d.model_type,
    ds.current_status,
    ds.battery_level,
    ds.signal_strength,
    ds.last_gps_lat,
    ds.last_gps_lon,
    ds.last_altitude_m,
    ds.firmware_version,
    ds.last_seen_at,
    fm.mission_ref     AS active_mission_ref,
    fm.mission_type    AS active_mission_type,
    z.zone_name        AS active_zone
FROM dsis.drones d
JOIN dsis.drone_status ds ON ds.drone_id = d.drone_id
LEFT JOIN dsis.flight_missions fm ON fm.mission_id = ds.active_mission_id
LEFT JOIN dsis.surveillance_zones z ON z.zone_id = fm.zone_id
WHERE d.is_active = TRUE;

COMMENT ON VIEW dsis.vw_active_fleet IS 'Real-time fleet overview joining drone, status, and active mission. Used by the operations dashboard.';

-- View 2: Open alerts with full context
CREATE OR REPLACE VIEW dsis.vw_open_alerts AS
SELECT
    a.alert_id,
    a.alert_ref,
    a.severity,
    a.title,
    a.description,
    a.created_at,
    z.zone_code,
    z.zone_name,
    z.zone_type,
    d.drone_ref,
    d.model_name AS drone_model,
    u.full_name  AS assigned_to_name,
    zrp.risk_level AS zone_risk_level,
    zrp.risk_score
FROM dsis.alerts a
JOIN dsis.surveillance_zones z  ON z.zone_id    = a.zone_id
LEFT JOIN dsis.drones d         ON d.drone_id   = a.drone_id
LEFT JOIN dsis.users u          ON u.user_id    = a.assigned_to
LEFT JOIN dsis.zone_risk_profile zrp ON zrp.zone_id = a.zone_id
WHERE a.status IN ('open', 'acknowledged', 'escalated')
ORDER BY
    CASE a.severity
        WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3
        WHEN 'low' THEN 4 ELSE 5
    END,
    a.created_at DESC;

COMMENT ON VIEW dsis.vw_open_alerts IS 'All actionable alerts with zone, drone, and risk context. Pre-sorted by severity for the alert management panel.';

-- View 3: Incident lifecycle summary
CREATE OR REPLACE VIEW dsis.vw_incident_summary AS
SELECT
    ir.incident_id,
    ir.incident_ref,
    ir.title,
    ir.status,
    ir.severity_rating,
    ir.opened_at,
    ir.resolved_at,
    EXTRACT(EPOCH FROM (COALESCE(ir.resolved_at, CURRENT_TIMESTAMP) - ir.opened_at)) / 3600 AS hours_open,
    z.zone_code,
    z.zone_name,
    rep.full_name  AS reported_by_name,
    asgn.full_name AS assigned_to_name,
    COUNT(es.evidence_id) AS evidence_count
FROM dsis.incident_reports ir
JOIN dsis.surveillance_zones z ON z.zone_id   = ir.zone_id
JOIN dsis.users rep             ON rep.user_id = ir.reported_by
LEFT JOIN dsis.users asgn       ON asgn.user_id= ir.assigned_to
LEFT JOIN dsis.evidence_storage es ON es.incident_id = ir.incident_id
GROUP BY ir.incident_id, ir.incident_ref, ir.title, ir.status, ir.severity_rating,
         ir.opened_at, ir.resolved_at, z.zone_code, z.zone_name, rep.full_name, asgn.full_name;

COMMENT ON VIEW dsis.vw_incident_summary IS 'Incident overview with time-open calculation and evidence count. Used for SLA tracking and report generation.';

-- View 4: Zone threat dashboard
CREATE OR REPLACE VIEW dsis.vw_zone_threat_dashboard AS
SELECT
    z.zone_id,
    z.zone_code,
    z.zone_name,
    z.zone_type,
    zrp.risk_level,
    zrp.risk_score,
    zrp.incident_count_30d,
    zrp.alert_count_30d,
    zrp.last_incident_at,
    zrp.next_review_at,
    COUNT(DISTINCT dza.drone_id) FILTER (WHERE dza.unassigned_at IS NULL) AS assigned_drone_count,
    COUNT(DISTINCT a.alert_id)   FILTER (WHERE a.status = 'open')         AS open_alert_count,
    MAX(wd.recorded_at)                                                    AS last_weather_update,
    MAX(wd.flight_clearance)                                               AS current_clearance
FROM dsis.surveillance_zones z
LEFT JOIN dsis.zone_risk_profile zrp        ON zrp.zone_id  = z.zone_id
LEFT JOIN dsis.drone_zone_assignments dza   ON dza.zone_id  = z.zone_id
LEFT JOIN dsis.alerts a                     ON a.zone_id    = z.zone_id
LEFT JOIN dsis.weather_data wd              ON wd.zone_id   = z.zone_id
WHERE z.is_active = TRUE
GROUP BY z.zone_id, z.zone_code, z.zone_name, z.zone_type,
         zrp.risk_level, zrp.risk_score, zrp.incident_count_30d,
         zrp.alert_count_30d, zrp.last_incident_at, zrp.next_review_at
ORDER BY zrp.risk_score DESC NULLS LAST;

COMMENT ON VIEW dsis.vw_zone_threat_dashboard IS 'Zone-level threat intelligence view. Aggregates risk score, drone coverage, open alerts, and weather clearance.';

-- View 5: Detection stats per zone (last 30 days)
CREATE OR REPLACE VIEW dsis.vw_detection_stats_30d AS
SELECT
    z.zone_code,
    z.zone_name,
    oc.category_name,
    do2.threat_level,
    COUNT(*)                                           AS detection_count,
    AVG(do2.confidence_score)                          AS avg_confidence,
    COUNT(*) FILTER (WHERE do2.is_confirmed = TRUE)    AS confirmed_count,
    COUNT(*) FILTER (WHERE do2.is_confirmed = FALSE)   AS pending_review_count,
    MAX(do2.detected_at)                               AS last_detected_at
FROM dsis.detected_objects do2
JOIN dsis.surveillance_zones z  ON z.zone_id    = do2.zone_id
JOIN dsis.object_categories oc  ON oc.category_id = do2.category_id
WHERE do2.detected_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY z.zone_code, z.zone_name, oc.category_name, do2.threat_level
ORDER BY detection_count DESC;

COMMENT ON VIEW dsis.vw_detection_stats_30d IS 'Rolling 30-day detection breakdown by zone, category, and threat level. Primary analytics view.';

-- Materialized View: Monthly alert trend (refresh nightly)
CREATE MATERIALIZED VIEW dsis.mvw_monthly_alert_trend AS
SELECT
    DATE_TRUNC('month', a.created_at)  AS month,
    z.zone_code,
    a.severity,
    COUNT(*)                           AS alert_count,
    COUNT(*) FILTER (WHERE a.status = 'resolved')     AS resolved_count,
    COUNT(*) FILTER (WHERE a.status = 'false_positive') AS false_positive_count,
    AVG(
        EXTRACT(EPOCH FROM (a.resolved_at - a.created_at)) / 3600
    ) FILTER (WHERE a.resolved_at IS NOT NULL)         AS avg_resolution_hours
FROM dsis.alerts a
JOIN dsis.surveillance_zones z ON z.zone_id = a.zone_id
GROUP BY DATE_TRUNC('month', a.created_at), z.zone_code, a.severity
ORDER BY month DESC, alert_count DESC
WITH DATA;

CREATE UNIQUE INDEX idx_mvw_alert_trend
    ON dsis.mvw_monthly_alert_trend (month, zone_code, severity);

COMMENT ON MATERIALIZED VIEW dsis.mvw_monthly_alert_trend IS
    'Pre-aggregated monthly alert statistics. Refresh with: REFRESH MATERIALIZED VIEW CONCURRENTLY dsis.mvw_monthly_alert_trend;';

-- ============================================================================================================================
-- SECTION 18: VERIFICATION QUERIES
-- (Run these to confirm the schema was created correctly)
-- ============================================================================================================================

-- Count all tables in dsis schema
SELECT
    schemaname,
    COUNT(*) AS table_count
FROM pg_tables
WHERE schemaname = 'dsis'
GROUP BY schemaname;

-- List all tables with row counts
SELECT
    relname   AS table_name,
    n_live_tup AS approximate_row_count
FROM pg_stat_user_tables
WHERE schemaname = 'dsis'
ORDER BY relname;

-- Count all indexes
SELECT COUNT(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'dsis';

-- List all ENUM types
SELECT
    t.typname  AS enum_type,
    array_agg(e.enumlabel ORDER BY e.enumsortorder) AS values
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'dsis'
GROUP BY t.typname
ORDER BY t.typname;

-- Verify FK relationships
SELECT
    tc.table_name              AS source_table,
    kcu.column_name            AS source_column,
    ccu.table_name             AS target_table,
    ccu.column_name            AS target_column,
    rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
    AND kcu.table_schema   = tc.table_schema
JOIN information_schema.referential_constraints rc
    ON rc.constraint_name  = tc.constraint_name
    AND rc.constraint_schema = tc.constraint_schema
JOIN information_schema.key_column_usage ccu
    ON ccu.constraint_name  = rc.unique_constraint_name
    AND ccu.constraint_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema    = 'dsis'
ORDER BY tc.table_name, kcu.column_name;

-- ============================================================================================================================
-- END OF PHASE 2 — DRONE SURVEILLANCE & INTELLIGENCE SYSTEM (DSIS)
-- ============================================================================================================================
-- SUMMARY:
--   Schema       : dsis
--   Tables       : 21 (+ partitions)
--   ENUM Types   : 24 custom types
--   Indexes      : 35+ (B-tree, GIN, BRIN, partial, covering)
--   Views        : 5 regular + 1 materialized
--   DB Roles     : 4 (dsis_admin, dsis_operator, dsis_analyst, dsis_viewer)
--   RLS Policies : 4
--   Partitioned  : flight_logs (8 monthly), detected_objects (6 monthly), audit_log (6 monthly)
--   Seed Data    : Users, Roles, Permissions, Drones, Zones, Missions, Detections, Alerts, Incidents
-- ============================================================================================================================
