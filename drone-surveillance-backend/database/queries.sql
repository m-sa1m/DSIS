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

