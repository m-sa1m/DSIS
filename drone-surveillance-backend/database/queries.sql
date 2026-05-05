-- ============================================================
-- Drone Surveillance & Intelligence System — Named Queries
-- GIK Institute of Engineering Sciences and Technology
-- ============================================================

-- ============================================================
-- Q1: Get all active drones with their assigned zone and current status
-- ============================================================
SELECT
    d.drone_id,
    d.drone_name,
    d.model,
    d.status,
    sz.zone_name,
    sz.risk_level
FROM drones d
LEFT JOIN surveillance_zones sz ON d.zone_id = sz.zone_id
WHERE d.status = 'Active'
ORDER BY d.drone_name;

-- ============================================================
-- Q2: Get all HIGH threat detections in the last 30 days with drone and zone info
-- ============================================================
SELECT
    do.detection_id,
    do.object_type,
    do.threat_level,
    do.detected_at,
    do.coordinates_lat,
    do.coordinates_lng,
    do.description,
    dr.drone_name,
    sz.zone_name
FROM detected_objects do
JOIN flight_logs fl ON do.log_id = fl.log_id
JOIN flight_missions fm ON fl.mission_id = fm.mission_id
JOIN drones dr ON fm.drone_id = dr.drone_id
JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
WHERE do.threat_level = 'High'
  AND do.detected_at >= NOW() - INTERVAL '30 days'
ORDER BY do.detected_at DESC;

-- ============================================================
-- Q3: Get monthly alert count grouped by severity for the current year
-- ============================================================
SELECT
    TO_CHAR(a.generated_at, 'YYYY-MM') AS month,
    a.severity,
    COUNT(*) AS alert_count
FROM alerts a
WHERE EXTRACT(YEAR FROM a.generated_at) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY TO_CHAR(a.generated_at, 'YYYY-MM'), a.severity
ORDER BY month, a.severity;

-- ============================================================
-- Q4: Get drone utilization — total missions and total flight minutes per drone
-- ============================================================
SELECT
    d.drone_name,
    COUNT(DISTINCT fm.mission_id) AS total_missions,
    COALESCE(SUM(fl.duration_minutes), 0) AS total_flight_minutes
FROM drones d
LEFT JOIN flight_missions fm ON d.drone_id = fm.drone_id
LEFT JOIN flight_logs fl ON fm.mission_id = fl.mission_id
GROUP BY d.drone_id, d.drone_name
ORDER BY total_missions DESC;

-- ============================================================
-- Q5: Get all unresolved incidents with the triggering alert and zone
-- ============================================================
SELECT
    ir.incident_id,
    ir.title,
    ir.incident_status,
    ir.created_at,
    a.severity,
    a.alert_status,
    sz.zone_name
FROM incident_reports ir
JOIN alerts a ON ir.alert_id = a.alert_id
JOIN detected_objects do ON a.detection_id = do.detection_id
JOIN flight_logs fl ON do.log_id = fl.log_id
JOIN flight_missions fm ON fl.mission_id = fm.mission_id
JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
WHERE ir.incident_status NOT IN ('Resolved', 'Archived')
ORDER BY ir.created_at DESC;

-- ============================================================
-- Q6: Get all zones ordered by number of HIGH detections descending (risk ranking)
-- ============================================================
SELECT
    sz.zone_id,
    sz.zone_name,
    sz.risk_level,
    COUNT(do.detection_id) AS high_detection_count
FROM surveillance_zones sz
LEFT JOIN flight_missions fm ON sz.zone_id = fm.zone_id
LEFT JOIN flight_logs fl ON fm.mission_id = fl.mission_id
LEFT JOIN detected_objects do ON fl.log_id = do.log_id AND do.threat_level = 'High'
GROUP BY sz.zone_id, sz.zone_name, sz.risk_level
ORDER BY high_detection_count DESC;

-- ============================================================
-- Q7: Get operator performance — number of missions completed per operator
-- ============================================================
SELECT
    u.user_id,
    u.full_name,
    COUNT(fm.mission_id) AS completed_missions
FROM users u
JOIN flight_missions fm ON u.user_id = fm.operator_id
WHERE fm.mission_status = 'Completed'
GROUP BY u.user_id, u.full_name
ORDER BY completed_missions DESC;

-- ============================================================
-- Q8: Full incident timeline: incident → alert → detection → flight log → mission → drone → zone
-- ============================================================
SELECT
    ir.incident_id,
    ir.title AS incident_title,
    ir.incident_status,
    a.alert_id,
    a.severity,
    a.alert_status,
    do.detection_id,
    do.object_type,
    do.threat_level,
    do.detected_at,
    fl.log_id,
    fl.start_time AS flight_start,
    fl.end_time AS flight_end,
    fl.duration_minutes,
    fm.mission_id,
    fm.mission_status,
    fm.scheduled_time,
    dr.drone_name,
    dr.model AS drone_model,
    sz.zone_name,
    sz.risk_level AS zone_risk
FROM incident_reports ir
JOIN alerts a ON ir.alert_id = a.alert_id
JOIN detected_objects do ON a.detection_id = do.detection_id
JOIN flight_logs fl ON do.log_id = fl.log_id
JOIN flight_missions fm ON fl.mission_id = fm.mission_id
JOIN drones dr ON fm.drone_id = dr.drone_id
JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
ORDER BY ir.created_at DESC;

-- ============================================================
-- Q9: Query performance comparison — WITH and WITHOUT index
-- ============================================================

-- 9a: Query USING the idx_detected_objects_threat index (default behavior)
-- The index idx_detected_objects_threat on detected_objects(threat_level)
-- allows PostgreSQL to perform an Index Scan instead of a Sequential Scan
-- when filtering by threat_level.
EXPLAIN ANALYZE
SELECT detection_id, object_type, threat_level, detected_at
FROM detected_objects
WHERE threat_level = 'High';

-- 9b: Query WITHOUT using the index (force Sequential Scan)
-- We temporarily disable index scans to compare performance.
-- In production this would show slower execution on large datasets.
SET enable_indexscan = OFF;
SET enable_bitmapscan = OFF;

EXPLAIN ANALYZE
SELECT detection_id, object_type, threat_level, detected_at
FROM detected_objects
WHERE threat_level = 'High';

-- Re-enable index scans
SET enable_indexscan = ON;
SET enable_bitmapscan = ON;

-- ============================================================
-- Q10: Get audit log for a specific user — all actions in the last 7 days
-- ============================================================
SELECT
    al.audit_id,
    al.action,
    al.table_name,
    al.record_id,
    al.description,
    al.performed_at,
    u.full_name
FROM audit_log al
JOIN users u ON al.user_id = u.user_id
WHERE al.user_id = 1
  AND al.performed_at >= NOW() - INTERVAL '7 days'
ORDER BY al.performed_at DESC;

-- ============================================================
-- Q11: Subquery — Find drones that have never been assigned a mission
-- ============================================================
SELECT
    d.drone_id,
    d.drone_name,
    d.model,
    d.status
FROM drones d
WHERE d.drone_id NOT IN (
    SELECT DISTINCT fm.drone_id
    FROM flight_missions fm
);

-- ============================================================
-- Q12: Subquery — Find zones where average threat level of detections is High
-- ============================================================
-- Mapping: High=3, Medium=2, Low=1. Average >= 2.5 means predominantly High.
SELECT
    sz.zone_id,
    sz.zone_name,
    sub.avg_threat
FROM surveillance_zones sz
JOIN (
    SELECT
        fm.zone_id,
        AVG(
            CASE do.threat_level
                WHEN 'High' THEN 3
                WHEN 'Medium' THEN 2
                WHEN 'Low' THEN 1
            END
        ) AS avg_threat
    FROM detected_objects do
    JOIN flight_logs fl ON do.log_id = fl.log_id
    JOIN flight_missions fm ON fl.mission_id = fm.mission_id
    GROUP BY fm.zone_id
    HAVING AVG(
        CASE do.threat_level
            WHEN 'High' THEN 3
            WHEN 'Medium' THEN 2
            WHEN 'Low' THEN 1
        END
    ) >= 2.5
) sub ON sz.zone_id = sub.zone_id
ORDER BY sub.avg_threat DESC;

-- ============================================================
-- Q13: Transaction example — Insert detection, trigger fires alert, then open incident
-- ============================================================
BEGIN;

-- Step 1: Insert a new High-threat detection (trigger auto-generates a Critical alert)
INSERT INTO detected_objects (log_id, object_type, threat_level, detected_at, coordinates_lat, coordinates_lng, description)
VALUES (1, 'Suspicious Drone', 'High', NOW(), 34.089200, 72.621500, 'Unregistered drone spotted above Main Gate')
RETURNING detection_id;

-- Step 2: Get the auto-generated alert for this detection
-- (The trigger created it; we retrieve it to link the incident)
-- In application code, use the detection_id from step 1:
-- SELECT alert_id FROM alerts WHERE detection_id = <returned_detection_id>;

-- Step 3: Create an incident linked to the alert
INSERT INTO incident_reports (alert_id, reported_by, title, description, incident_status)
SELECT
    a.alert_id,
    1,
    'Unregistered Drone at Main Gate',
    'An unregistered drone was spotted flying above the Main Gate area. Security team alerted.',
    'Open'
FROM alerts a
WHERE a.detection_id = (SELECT MAX(detection_id) FROM detected_objects WHERE object_type = 'Suspicious Drone');

COMMIT;
-- If any step fails, use: ROLLBACK;

-- ============================================================
-- Q14: BCNF Demonstration — Show functional dependencies are satisfied
-- ============================================================
-- In our schema, the roles table is in BCNF because:
-- role_id → role_name, description (role_id is the sole candidate key)
-- role_name → role_id, description (role_name is also a candidate key, enforced by UNIQUE)
--
-- The users table satisfies BCNF because:
-- user_id → full_name, email, password_hash, role_id, is_active, created_at
-- email → user_id, full_name, ... (email is a candidate key, enforced by UNIQUE)
--
-- We demonstrate that the role → permissions relationship has no partial or
-- transitive dependencies by showing that each role maps to a consistent
-- set of user attributes:

SELECT
    r.role_id,
    r.role_name,
    r.description AS role_description,
    COUNT(u.user_id) AS user_count,
    ARRAY_AGG(u.full_name ORDER BY u.full_name) AS users_in_role
FROM roles r
LEFT JOIN users u ON r.role_id = u.role_id
GROUP BY r.role_id, r.role_name, r.description
ORDER BY r.role_id;

-- Verify no user has ambiguous role assignment (each user_id determines exactly one role_id)
SELECT
    u.user_id,
    u.full_name,
    u.email,
    r.role_name,
    r.description AS role_permissions
FROM users u
JOIN roles r ON u.role_id = r.role_id
ORDER BY u.user_id;
