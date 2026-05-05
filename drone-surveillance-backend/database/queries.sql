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

