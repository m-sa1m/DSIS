-- ============================================================================================================================
-- PROJECT      : Drone Surveillance & Intelligence System (DSIS)
-- FILE         : phase2_queries.sql
-- PHASE        : Phase 2 — SQL Query Design
-- AUTHOR       : Muhammad Saim | Reg# 2024453 | CYS
-- DATABASE     : PostgreSQL 16+
-- DESCRIPTION  : Comprehensive query library — CRUD, Aggregations, Analytical, Subqueries,
--                Window Functions, CTEs, RBAC, and Performance Benchmarks
-- ============================================================================================================================

SET search_path = dsis, public;

-- ============================================================================================================================
-- PART A — CRUD OPERATIONS
-- ============================================================================================================================

-- ─────────────────────────────────────────────────────────────────
-- A.1  CREATE (INSERT) OPERATIONS
-- ─────────────────────────────────────────────────────────────────

-- A.1.1 Register a new drone
INSERT INTO dsis.drones (
    serial_number, model_name, model_type, manufacturer,
    manufacture_date, purchase_date, warranty_expiry,
    max_flight_time, max_range_km, max_altitude_m,
    camera_specs, payload_capacity_kg
)
VALUES (
    'SN-DJI-M300-006',
    'DJI Matrice 300 RTK',
    'hexacopter',
    'DJI Technology',
    '2024-01-10',
    '2024-03-15',
    '2026-03-15',
    55,
    15.00,
    7000,
    '{"resolution":"45MP","thermal":true,"night_vision":true,"optical_zoom":200,"rtk_gps":true}'::jsonb,
    2.7
)
ON CONFLICT (serial_number) DO NOTHING;

-- A.1.2 Create a new flight mission
INSERT INTO dsis.flight_missions (
    drone_id, zone_id, operator_id, mission_type,
    status, priority, planned_start_at, planned_end_at,
    planned_altitude_m, briefing_notes
)
SELECT
    d.drone_id,
    z.zone_id,
    u.user_id,
    'routine_patrol'::dsis.mission_type_t,
    'planned'::dsis.mission_status_t,
    3,
    CURRENT_TIMESTAMP + INTERVAL '2 hours',
    CURRENT_TIMESTAMP + INTERVAL '3 hours',
    80,
    'Evening patrol covering north fence line and parking structure'
FROM dsis.drones d, dsis.surveillance_zones z, dsis.users u
WHERE d.serial_number = 'SN-DJI-M30T-001'
  AND z.zone_code     = 'ZONE-ALPHA'
  AND u.username      = 'op_ali';

-- A.1.3 Log a new detection (UPSERT-safe insert)
INSERT INTO dsis.detected_objects (
    mission_id, drone_id, zone_id, category_id,
    threat_level, movement_type, confidence_score,
    latitude, longitude, altitude_m, object_count, detected_at
)
SELECT
    fm.mission_id,
    fm.drone_id,
    fm.zone_id,
    oc.category_id,
    'medium'::dsis.threat_level_t,
    'running'::dsis.movement_t,
    0.8841,
    33.7301, 73.0945,
    75.5, 1,
    CURRENT_TIMESTAMP
FROM dsis.flight_missions fm, dsis.object_categories oc
WHERE fm.mission_type = 'routine_patrol'
  AND oc.sub_category = 'civilian'
LIMIT 1;

-- A.1.4 Create an alert manually
INSERT INTO dsis.alerts (
    zone_id, severity, status, title,
    description, auto_generated
)
SELECT
    zone_id,
    'medium'::dsis.alert_severity_t,
    'open'::dsis.alert_status_t,
    'Perimeter Breach Warning — Zone ALPHA',
    'Operator reported possible perimeter fence cut on north-west side. Ground response required.',
    FALSE
FROM dsis.surveillance_zones
WHERE zone_code = 'ZONE-ALPHA';

-- A.1.5 Register a user session on login
INSERT INTO dsis.user_sessions (user_id, token_hash, ip_address, user_agent, expires_at)
SELECT
    user_id,
    encode(digest('session_token_example_' || user_id::text, 'sha256'), 'hex'),
    '192.168.1.100'::inet,
    'Mozilla/5.0 DSIS-Dashboard/1.0',
    CURRENT_TIMESTAMP + INTERVAL '8 hours'
FROM dsis.users
WHERE username = 'op_ali';

-- ─────────────────────────────────────────────────────────────────
-- A.2  READ (SELECT) OPERATIONS
-- ─────────────────────────────────────────────────────────────────

-- A.2.1 Get full drone fleet status (join 3 tables)
SELECT
    d.drone_ref,
    d.serial_number,
    d.model_name,
    d.model_type,
    ds.current_status,
    ds.battery_level          AS battery_pct,
    ds.signal_strength        AS signal_pct,
    ROUND(ds.last_gps_lat::numeric, 5) AS last_lat,
    ROUND(ds.last_gps_lon::numeric, 5) AS last_lon,
    ds.firmware_version,
    ds.last_seen_at
FROM dsis.drones d
JOIN dsis.drone_status ds ON ds.drone_id = d.drone_id
WHERE d.is_active = TRUE
ORDER BY ds.current_status, ds.battery_level DESC;

-- A.2.2 Get all detections for a specific zone in the last 24 hours
SELECT
    do2.detection_id,
    do2.threat_level,
    oc.category_name,
    oc.sub_category,
    do2.movement_type,
    do2.confidence_score,
    do2.latitude,
    do2.longitude,
    do2.object_count,
    do2.is_confirmed,
    do2.detected_at,
    d.drone_ref
FROM dsis.detected_objects do2
JOIN dsis.object_categories   oc ON oc.category_id = do2.category_id
JOIN dsis.drones               d ON d.drone_id      = do2.drone_id
JOIN dsis.surveillance_zones   z ON z.zone_id       = do2.zone_id
WHERE z.zone_code  = 'ZONE-DELTA'
  AND do2.detected_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY do2.detected_at DESC;

-- A.2.3 Get a user's full permission set
SELECT
    u.full_name,
    u.username,
    r.display_name AS role,
    array_agg(p.permission_code ORDER BY p.resource, p.action) AS permissions
FROM dsis.users u
JOIN dsis.roles r            ON r.role_id       = u.role_id
JOIN dsis.role_permissions rp ON rp.role_id     = r.role_id
JOIN dsis.permissions p      ON p.permission_id = rp.permission_id
WHERE u.username = 'analyst_zara'
GROUP BY u.full_name, u.username, r.display_name;

-- A.2.4 Get current weather clearance status per zone
SELECT
    z.zone_code,
    z.zone_name,
    wd.condition,
    wd.temperature_c,
    wd.wind_speed_ms,
    wd.visibility_km,
    wd.flight_clearance,
    wd.clearance_reason,
    wd.recorded_at
FROM dsis.surveillance_zones z
JOIN LATERAL (
    SELECT * FROM dsis.weather_data w
    WHERE w.zone_id = z.zone_id
    ORDER BY w.recorded_at DESC
    LIMIT 1
) wd ON TRUE
WHERE z.is_active = TRUE
ORDER BY
    CASE wd.flight_clearance
        WHEN 'grounded'         THEN 1
        WHEN 'not_recommended'  THEN 2
        WHEN 'marginal'         THEN 3
        WHEN 'approved'         THEN 4
    END;

-- ─────────────────────────────────────────────────────────────────
-- A.3  UPDATE OPERATIONS
-- ─────────────────────────────────────────────────────────────────

-- A.3.1 Update drone status when mission starts
UPDATE dsis.drone_status
SET
    current_status    = 'in_mission',
    active_mission_id = (
        SELECT mission_id FROM dsis.flight_missions
        WHERE status = 'planned'
        ORDER BY planned_start_at
        LIMIT 1
    ),
    updated_at        = CURRENT_TIMESTAMP
WHERE drone_id = (SELECT drone_id FROM dsis.drones WHERE serial_number = 'SN-DJI-M30T-001');

-- A.3.2 Acknowledge an alert
UPDATE dsis.alerts
SET
    status           = 'acknowledged',
    acknowledged_by  = (SELECT user_id FROM dsis.users WHERE username = 'analyst_zara'),
    acknowledged_at  = CURRENT_TIMESTAMP
WHERE status = 'open'
  AND severity IN ('high', 'critical')
  AND assigned_to IS NULL
RETURNING alert_id, alert_ref, title, status;

-- A.3.3 Confirm a detection after human review
UPDATE dsis.detected_objects
SET
    is_confirmed  = TRUE,
    confirmed_by  = (SELECT user_id FROM dsis.users WHERE username = 'analyst_zara'),
    confirmed_at  = CURRENT_TIMESTAMP
WHERE threat_level IN ('high', 'critical')
  AND is_confirmed = FALSE
  AND detected_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';

-- A.3.4 Update zone risk profile after new incident
UPDATE dsis.zone_risk_profile
SET
    incident_count_30d = incident_count_30d + 1,
    last_incident_at   = CURRENT_TIMESTAMP,
    risk_score         = LEAST(risk_score + 5.0, 100.0),
    risk_level         = CASE
                             WHEN LEAST(risk_score + 5.0, 100.0) >= 75 THEN 'critical'
                             WHEN LEAST(risk_score + 5.0, 100.0) >= 50 THEN 'high'
                             WHEN LEAST(risk_score + 5.0, 100.0) >= 25 THEN 'moderate'
                             ELSE 'low'
                         END::dsis.risk_level_t,
    assessed_at        = CURRENT_TIMESTAMP,
    updated_at         = CURRENT_TIMESTAMP
WHERE zone_id = (SELECT zone_id FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-DELTA');

-- A.3.5 Progress incident lifecycle: open → under_review
UPDATE dsis.incident_reports
SET
    status          = 'under_review',
    under_review_at = CURRENT_TIMESTAMP,
    response_notes  = 'Forensic drone footage reviewed. Ground team dispatched. Awaiting field report.',
    updated_at      = CURRENT_TIMESTAMP
WHERE status = 'open'
  AND severity_rating >= 3;

-- ─────────────────────────────────────────────────────────────────
-- A.4  DELETE / SOFT-DELETE OPERATIONS
-- ─────────────────────────────────────────────────────────────────

-- A.4.1 Soft-delete: decommission a drone (never hard-delete operational data)
UPDATE dsis.drones
SET
    is_active  = FALSE,
    updated_at = CURRENT_TIMESTAMP
WHERE serial_number = 'SN-PARROT-ANAFI-004'
  AND NOT EXISTS (
      SELECT 1 FROM dsis.flight_missions
      WHERE drone_id = dsis.drones.drone_id
        AND status = 'in_progress'
  );

-- A.4.2 Revoke a user session (logout)
UPDATE dsis.user_sessions
SET
    revoked_at    = CURRENT_TIMESTAMP,
    revoke_reason = 'user_logout'
WHERE user_id   = (SELECT user_id FROM dsis.users WHERE username = 'op_ali')
  AND revoked_at IS NULL;

-- A.4.3 Hard-delete stale planned missions older than 7 days (never started)
DELETE FROM dsis.flight_missions
WHERE status            = 'planned'
  AND planned_start_at  < CURRENT_TIMESTAMP - INTERVAL '7 days'
  AND actual_start_at   IS NULL;

-- A.4.4 Archive old resolved incidents (soft)
UPDATE dsis.incident_reports
SET
    status      = 'archived',
    archived_at = CURRENT_TIMESTAMP,
    updated_at  = CURRENT_TIMESTAMP
WHERE status       = 'resolved'
  AND resolved_at  < CURRENT_TIMESTAMP - INTERVAL '90 days';

-- ============================================================================================================================
-- PART B — AGGREGATION & REPORTING QUERIES
-- ============================================================================================================================

-- B.1 Drone utilisation report (mission hours per drone, last 30 days)
SELECT
    d.drone_ref,
    d.model_name,
    COUNT(fm.mission_id)                                              AS total_missions,
    COUNT(fm.mission_id) FILTER (WHERE fm.status = 'completed')      AS completed_missions,
    COUNT(fm.mission_id) FILTER (WHERE fm.status = 'aborted')        AS aborted_missions,
    ROUND(
        SUM(
            EXTRACT(EPOCH FROM (fm.actual_end_at - fm.actual_start_at)) / 3600.0
        ) FILTER (WHERE fm.actual_end_at IS NOT NULL),
        2
    )                                                                  AS total_flight_hours,
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (fm.actual_end_at - fm.actual_start_at)) / 60.0
        ) FILTER (WHERE fm.actual_end_at IS NOT NULL),
        1
    )                                                                  AS avg_mission_minutes
FROM dsis.drones d
LEFT JOIN dsis.flight_missions fm
    ON fm.drone_id    = d.drone_id
    AND fm.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
WHERE d.is_active = TRUE
GROUP BY d.drone_id, d.drone_ref, d.model_name
ORDER BY total_flight_hours DESC NULLS LAST;

-- B.2 Monthly alert trend report
SELECT
    TO_CHAR(DATE_TRUNC('month', a.created_at), 'YYYY-MM') AS month,
    a.severity,
    COUNT(*)                                               AS total_alerts,
    COUNT(*) FILTER (WHERE a.status = 'resolved')         AS resolved,
    COUNT(*) FILTER (WHERE a.status = 'false_positive')   AS false_positives,
    COUNT(*) FILTER (WHERE a.status = 'open')             AS still_open,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (a.resolved_at - a.created_at)) / 3600.0)
        FILTER (WHERE a.resolved_at IS NOT NULL), 2
    )                                                      AS avg_resolution_hrs
FROM dsis.alerts a
WHERE a.created_at >= CURRENT_TIMESTAMP - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', a.created_at), a.severity
ORDER BY month DESC, a.severity;

-- B.3 High-risk zone analysis report
SELECT
    z.zone_code,
    z.zone_name,
    z.zone_type,
    zrp.risk_level,
    zrp.risk_score,
    zrp.incident_count_30d,
    zrp.alert_count_30d,
    COUNT(DISTINCT do2.detection_id) FILTER (
        WHERE do2.threat_level IN ('high','critical')
          AND do2.detected_at  >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    )                                                      AS high_threat_detections_30d,
    COUNT(DISTINCT fm.mission_id)                          AS total_missions,
    zrp.next_review_at
FROM dsis.surveillance_zones z
LEFT JOIN dsis.zone_risk_profile     zrp ON zrp.zone_id  = z.zone_id
LEFT JOIN dsis.detected_objects      do2 ON do2.zone_id  = z.zone_id
LEFT JOIN dsis.flight_missions        fm ON fm.zone_id   = z.zone_id
WHERE z.is_active = TRUE
GROUP BY z.zone_id, z.zone_code, z.zone_name, z.zone_type,
         zrp.risk_level, zrp.risk_score, zrp.incident_count_30d,
         zrp.alert_count_30d, zrp.next_review_at
ORDER BY zrp.risk_score DESC NULLS LAST;

-- B.4 Object category detection frequency report (threat breakdown)
SELECT
    oc.category_name,
    oc.sub_category,
    oc.default_threat,
    COUNT(do2.detection_id)                                     AS total_detections,
    COUNT(do2.detection_id) FILTER (WHERE do2.is_confirmed)     AS confirmed,
    ROUND(AVG(do2.confidence_score)::numeric, 4)                AS avg_ai_confidence,
    COUNT(DISTINCT do2.zone_id)                                 AS zones_affected,
    MAX(do2.detected_at)                                        AS most_recent_detection
FROM dsis.object_categories oc
LEFT JOIN dsis.detected_objects do2 ON do2.category_id = oc.category_id
WHERE oc.is_active = TRUE
GROUP BY oc.category_id, oc.category_name, oc.sub_category, oc.default_threat
ORDER BY total_detections DESC;

-- B.5 Drone health anomaly summary
SELECT
    d.drone_ref,
    d.model_name,
    dhl.metric,
    COUNT(*)                                               AS total_readings,
    COUNT(*) FILTER (WHERE dhl.is_anomaly)                 AS anomaly_count,
    ROUND(AVG(dhl.value_numeric)::numeric, 3)              AS avg_value,
    MIN(dhl.value_numeric)                                 AS min_value,
    MAX(dhl.value_numeric)                                 AS max_value,
    MAX(dhl.recorded_at) FILTER (WHERE dhl.is_anomaly)     AS last_anomaly_at
FROM dsis.drones d
JOIN dsis.drone_health_log dhl ON dhl.drone_id = d.drone_id
WHERE dhl.recorded_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY d.drone_id, d.drone_ref, d.model_name, dhl.metric
HAVING COUNT(*) FILTER (WHERE dhl.is_anomaly) > 0
ORDER BY anomaly_count DESC;

-- ============================================================================================================================
-- PART C — ADVANCED ANALYTICAL QUERIES
-- ============================================================================================================================

-- C.1 CTE: Incident resolution SLA analysis (>24h = SLA breach)
WITH incident_timing AS (
    SELECT
        ir.incident_id,
        ir.incident_ref,
        ir.title,
        ir.severity_rating,
        ir.status,
        z.zone_name,
        ir.opened_at,
        ir.resolved_at,
        EXTRACT(EPOCH FROM (
            COALESCE(ir.resolved_at, CURRENT_TIMESTAMP) - ir.opened_at
        )) / 3600.0 AS hours_to_resolve
    FROM dsis.incident_reports ir
    JOIN dsis.surveillance_zones z ON z.zone_id = ir.zone_id
),
sla_thresholds AS (
    SELECT
        severity_rating,
        CASE severity_rating
            WHEN 5 THEN 2.0
            WHEN 4 THEN 4.0
            WHEN 3 THEN 8.0
            WHEN 2 THEN 24.0
            ELSE 72.0
        END AS sla_hours
    FROM generate_series(1, 5) AS t(severity_rating)
)
SELECT
    it.incident_ref,
    it.severity_rating,
    it.zone_name,
    it.status,
    ROUND(it.hours_to_resolve::numeric, 2)  AS hours_open,
    st.sla_hours,
    CASE
        WHEN it.hours_to_resolve > st.sla_hours THEN 'SLA BREACHED'
        WHEN it.status = 'resolved'             THEN 'RESOLVED IN SLA'
        ELSE 'IN PROGRESS'
    END AS sla_status
FROM incident_timing it
JOIN sla_thresholds st USING (severity_rating)
ORDER BY hours_to_resolve DESC;

-- C.2 Window Function: Rank drones by detection volume per zone
SELECT
    z.zone_name,
    d.drone_ref,
    d.model_name,
    COUNT(do2.detection_id)                                   AS detection_count,
    RANK() OVER (
        PARTITION BY z.zone_id
        ORDER BY COUNT(do2.detection_id) DESC
    )                                                          AS zone_rank,
    ROUND(
        100.0 * COUNT(do2.detection_id) /
        NULLIF(SUM(COUNT(do2.detection_id)) OVER (PARTITION BY z.zone_id), 0),
        2
    )                                                          AS pct_of_zone_detections
FROM dsis.detected_objects do2
JOIN dsis.surveillance_zones z ON z.zone_id  = do2.zone_id
JOIN dsis.drones              d ON d.drone_id = do2.drone_id
WHERE do2.detected_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY z.zone_id, z.zone_name, d.drone_id, d.drone_ref, d.model_name
ORDER BY z.zone_name, zone_rank;

-- C.3 Window Function: Running total of alerts per zone (cumulative timeline)
SELECT
    DATE_TRUNC('day', a.created_at)       AS alert_day,
    z.zone_code,
    COUNT(*)                              AS daily_alerts,
    SUM(COUNT(*)) OVER (
        PARTITION BY z.zone_id
        ORDER BY DATE_TRUNC('day', a.created_at)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                     AS running_total,
    AVG(COUNT(*)) OVER (
        PARTITION BY z.zone_id
        ORDER BY DATE_TRUNC('day', a.created_at)
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )                                     AS rolling_7day_avg
FROM dsis.alerts a
JOIN dsis.surveillance_zones z ON z.zone_id = a.zone_id
WHERE a.created_at >= CURRENT_TIMESTAMP - INTERVAL '90 days'
GROUP BY DATE_TRUNC('day', a.created_at), z.zone_id, z.zone_code
ORDER BY zone_code, alert_day;

-- C.4 Window Function: LAG/LEAD — detect battery degradation trend per drone
SELECT
    d.drone_ref,
    dhl.recorded_at,
    dhl.value_numeric              AS battery_voltage,
    LAG(dhl.value_numeric)  OVER w AS prev_reading,
    LEAD(dhl.value_numeric) OVER w AS next_reading,
    dhl.value_numeric - LAG(dhl.value_numeric) OVER w AS delta_from_prev,
    CASE
        WHEN dhl.value_numeric < LAG(dhl.value_numeric) OVER w THEN 'DECLINING'
        WHEN dhl.value_numeric > LAG(dhl.value_numeric) OVER w THEN 'IMPROVING'
        ELSE 'STABLE'
    END AS trend
FROM dsis.drone_health_log dhl
JOIN dsis.drones d ON d.drone_id = dhl.drone_id
WHERE dhl.metric = 'battery'
WINDOW w AS (PARTITION BY dhl.drone_id ORDER BY dhl.recorded_at)
ORDER BY d.drone_ref, dhl.recorded_at;

-- C.5 CTE Recursive: Alert escalation chain (trace full escalation history)
WITH RECURSIVE escalation_chain AS (
    -- Base: the original alert creation
    SELECT
        a.alert_id,
        a.alert_ref,
        a.title,
        a.severity,
        a.created_at       AS event_time,
        'Alert Created'    AS event_type,
        NULL::uuid         AS performed_by_id,
        0                  AS depth
    FROM dsis.alerts a
    WHERE a.alert_ref LIKE 'ALR-%'

    UNION ALL

    -- Recursive: escalation steps
    SELECT
        ec.alert_id,
        ec.alert_ref,
        ec.title,
        ec.severity,
        ael.performed_at   AS event_time,
        ael.action_taken::text AS event_type,
        ael.performed_by   AS performed_by_id,
        ec.depth + 1       AS depth
    FROM escalation_chain ec
    JOIN dsis.alert_escalation_log ael ON ael.alert_id = ec.alert_id
    WHERE ec.depth < 10    -- prevent infinite recursion
)
SELECT
    ec.alert_ref,
    ec.title,
    ec.severity,
    ec.depth,
    ec.event_type,
    u.full_name AS performed_by,
    ec.event_time
FROM escalation_chain ec
LEFT JOIN dsis.users u ON u.user_id = ec.performed_by_id
ORDER BY ec.alert_ref, ec.event_time;

-- C.6 Complex JOIN: Full mission intelligence briefing (6-table join)
SELECT
    fm.mission_ref,
    fm.mission_type,
    fm.status          AS mission_status,
    fm.priority,
    d.drone_ref,
    d.model_name       AS drone_model,
    z.zone_name,
    z.zone_type,
    zrp.risk_level     AS zone_risk,
    op.full_name       AS operator_name,
    wd.condition       AS weather,
    wd.flight_clearance,
    wd.wind_speed_ms,
    COUNT(do2.detection_id)                                  AS total_detections,
    COUNT(do2.detection_id) FILTER (
        WHERE do2.threat_level IN ('high','critical')
    )                                                         AS high_threat_detections,
    fm.planned_start_at,
    fm.planned_end_at
FROM dsis.flight_missions fm
JOIN dsis.drones               d   ON d.drone_id   = fm.drone_id
JOIN dsis.surveillance_zones   z   ON z.zone_id    = fm.zone_id
JOIN dsis.users                op  ON op.user_id   = fm.operator_id
LEFT JOIN dsis.zone_risk_profile zrp ON zrp.zone_id = z.zone_id
LEFT JOIN dsis.weather_data    wd  ON wd.zone_id   = z.zone_id
                                   AND wd.recorded_at = (
                                       SELECT MAX(w2.recorded_at)
                                       FROM dsis.weather_data w2
                                       WHERE w2.zone_id = z.zone_id
                                   )
LEFT JOIN dsis.detected_objects do2 ON do2.mission_id = fm.mission_id
GROUP BY fm.mission_id, fm.mission_ref, fm.mission_type, fm.status, fm.priority,
         d.drone_ref, d.model_name, z.zone_name, z.zone_type,
         zrp.risk_level, op.full_name, wd.condition, wd.flight_clearance, wd.wind_speed_ms,
         fm.planned_start_at, fm.planned_end_at
ORDER BY fm.priority, fm.planned_start_at;

-- ============================================================================================================================
-- PART D — SUBQUERY QUERIES
-- ============================================================================================================================

-- D.1 Correlated subquery: Drones that have NEVER been assigned to a high-risk zone
SELECT
    d.drone_ref,
    d.model_name,
    d.model_type
FROM dsis.drones d
WHERE d.is_active = TRUE
  AND NOT EXISTS (
      SELECT 1
      FROM dsis.drone_zone_assignments dza
      JOIN dsis.zone_risk_profile zrp ON zrp.zone_id = dza.zone_id
      WHERE dza.drone_id      = d.drone_id
        AND dza.unassigned_at IS NULL
        AND zrp.risk_level    IN ('high', 'critical')
  )
ORDER BY d.model_name;

-- D.2 Scalar subquery: Each zone's detection count vs. system-wide average
SELECT
    z.zone_code,
    z.zone_name,
    (SELECT COUNT(*) FROM dsis.detected_objects do2 WHERE do2.zone_id = z.zone_id)
        AS zone_detection_count,
    (SELECT ROUND(AVG(cnt), 0) FROM (
         SELECT COUNT(*) AS cnt FROM dsis.detected_objects GROUP BY zone_id
     ) sub)
        AS system_avg_detections,
    CASE
        WHEN (SELECT COUNT(*) FROM dsis.detected_objects do2 WHERE do2.zone_id = z.zone_id)
           > (SELECT AVG(cnt) FROM (SELECT COUNT(*) AS cnt FROM dsis.detected_objects GROUP BY zone_id) sub)
        THEN 'ABOVE AVERAGE'
        ELSE 'BELOW AVERAGE'
    END AS vs_average
FROM dsis.surveillance_zones z
WHERE z.is_active = TRUE
ORDER BY zone_detection_count DESC;

-- D.3 IN subquery: Alerts linked to high-severity incidents
SELECT
    a.alert_ref,
    a.title,
    a.severity,
    a.status,
    a.created_at
FROM dsis.alerts a
WHERE a.alert_id IN (
    SELECT ir.alert_id
    FROM dsis.incident_reports ir
    WHERE ir.severity_rating >= 4
      AND ir.status NOT IN ('archived', 'cancelled')
)
ORDER BY a.created_at DESC;

-- D.4 EXISTS subquery: Zones with at least one unprocessed video awaiting AI analysis
SELECT
    z.zone_code,
    z.zone_name,
    zrp.risk_level,
    COUNT(vm.video_id) AS unprocessed_videos
FROM dsis.surveillance_zones z
JOIN dsis.zone_risk_profile zrp ON zrp.zone_id = z.zone_id
JOIN dsis.flight_missions fm    ON fm.zone_id   = z.zone_id
JOIN dsis.video_metadata vm     ON vm.mission_id = fm.mission_id
WHERE vm.is_processed = FALSE
  AND EXISTS (
      SELECT 1 FROM dsis.alerts a
      WHERE a.zone_id  = z.zone_id
        AND a.status   = 'open'
  )
GROUP BY z.zone_id, z.zone_code, z.zone_name, zrp.risk_level
ORDER BY unprocessed_videos DESC;

-- D.5 LATERAL subquery: Most recent flight log reading per active mission
SELECT
    fm.mission_ref,
    fm.mission_type,
    z.zone_name,
    latest_log.latitude,
    latest_log.longitude,
    latest_log.altitude_m,
    latest_log.speed_kmh,
    latest_log.battery_pct,
    latest_log.logged_at
FROM dsis.flight_missions fm
JOIN dsis.surveillance_zones z ON z.zone_id = fm.zone_id
JOIN LATERAL (
    SELECT *
    FROM dsis.flight_logs fl
    WHERE fl.mission_id = fm.mission_id
    ORDER BY fl.logged_at DESC
    LIMIT 1
) latest_log ON TRUE
WHERE fm.status = 'in_progress';

-- ============================================================================================================================
-- PART E — ROLE-BASED ACCESS CONTROL QUERIES
-- ============================================================================================================================

-- E.1 RBAC: Check if user has a specific permission (used by backend middleware)
SELECT
    u.username,
    u.full_name,
    r.role_name,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM dsis.role_permissions rp
            JOIN dsis.permissions p ON p.permission_id = rp.permission_id
            WHERE rp.role_id         = u.role_id
              AND p.permission_code  = 'alert:escalate'
        )
        THEN TRUE
        ELSE FALSE
    END AS has_escalate_permission
FROM dsis.users u
JOIN dsis.roles r ON r.role_id = u.role_id
WHERE u.status = 'active';

-- E.2 RBAC: Permission matrix — all roles vs. all permissions
SELECT
    r.display_name                                              AS role,
    array_agg(p.permission_code ORDER BY p.resource, p.action)
        FILTER (WHERE rp.permission_id IS NOT NULL)             AS granted_permissions,
    COUNT(rp.permission_id)                                     AS permission_count
FROM dsis.roles r
CROSS JOIN dsis.permissions p
LEFT JOIN dsis.role_permissions rp
    ON rp.role_id = r.role_id AND rp.permission_id = p.permission_id
GROUP BY r.role_id, r.role_name, r.display_name
ORDER BY permission_count DESC;

-- E.3 RBAC: Detect privilege escalation — users with more permissions than their role should have
WITH expected_perms AS (
    SELECT rp.role_id, COUNT(*) AS expected_count
    FROM dsis.role_permissions rp
    GROUP BY rp.role_id
)
SELECT
    u.username,
    r.role_name,
    ep.expected_count AS expected_permissions,
    (SELECT COUNT(*) FROM dsis.role_permissions rp2 WHERE rp2.role_id = u.role_id)
        AS actual_permissions,
    CASE
        WHEN (SELECT COUNT(*) FROM dsis.role_permissions rp2 WHERE rp2.role_id = u.role_id)
           > ep.expected_count
        THEN 'POTENTIAL ESCALATION DETECTED'
        ELSE 'NORMAL'
    END AS escalation_check
FROM dsis.users u
JOIN dsis.roles r ON r.role_id = u.role_id
JOIN expected_perms ep ON ep.role_id = u.role_id
WHERE u.status = 'active'
ORDER BY u.username;

-- E.4 RBAC: View access denied events from audit log
SELECT
    al.logged_at,
    u.username,
    r.role_name,
    al.action,
    al.table_name,
    al.error_message,
    al.ip_address
FROM dsis.audit_log al
LEFT JOIN dsis.users u ON u.user_id = al.user_id
LEFT JOIN dsis.roles r ON r.role_id = u.role_id
WHERE al.status = 'denied'
ORDER BY al.logged_at DESC
LIMIT 100;

-- E.5 RBAC: Verify RLS is active on sensitive tables
SELECT
    n.nspname   AS schema_name,
    c.relname   AS table_name,
    c.relrowsecurity AS rls_enabled,
    COUNT(pol.polname) AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy pol ON pol.polrelid = c.oid
WHERE n.nspname = 'dsis'
  AND c.relkind = 'r'
GROUP BY n.nspname, c.relname, c.relrowsecurity
ORDER BY rls_enabled DESC, c.relname;

-- ============================================================================================================================
-- PART F — PERFORMANCE BENCHMARK QUERIES (Indexed vs Non-Indexed Comparison)
-- ============================================================================================================================

-- ─────────────────────────────────────────────────────────────────
-- F.1 Benchmark Setup: Create a table WITHOUT indexes for comparison
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS dsis.detected_objects_noindex AS
SELECT * FROM dsis.detected_objects;

COMMENT ON TABLE dsis.detected_objects_noindex IS
    'BENCHMARK ONLY: Copy of detected_objects with no indexes. Used to demonstrate index performance gains.';

-- ─────────────────────────────────────────────────────────────────
-- F.2 Run EXPLAIN ANALYZE on indexed table
-- ─────────────────────────────────────────────────────────────────

-- Query: Find all high-threat detections in a zone over last 7 days
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT detection_id, threat_level, confidence_score, detected_at
FROM dsis.detected_objects
WHERE zone_id     = (SELECT zone_id FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-CHARLIE')
  AND threat_level IN ('high', 'critical')
  AND detected_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
ORDER BY detected_at DESC;

-- ─────────────────────────────────────────────────────────────────
-- F.3 Run same query on non-indexed copy (will show Seq Scan)
-- ─────────────────────────────────────────────────────────────────

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT detection_id, threat_level, confidence_score, detected_at
FROM dsis.detected_objects_noindex
WHERE zone_id      = (SELECT zone_id FROM dsis.surveillance_zones WHERE zone_code = 'ZONE-CHARLIE')
  AND threat_level IN ('high', 'critical')
  AND detected_at  >= CURRENT_TIMESTAMP - INTERVAL '7 days'
ORDER BY detected_at DESC;

-- NOTE: Compare "Planning Time", "Execution Time", and scan type (Index Scan vs Seq Scan)
-- Include screenshots of both EXPLAIN outputs in your project report as evidence of optimization.

-- ─────────────────────────────────────────────────────────────────
-- F.4 Index usage statistics (show which indexes are being used)
-- ─────────────────────────────────────────────────────────────────

SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan       AS times_used,
    idx_tup_read   AS rows_read_via_index,
    idx_tup_fetch  AS rows_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'dsis'
ORDER BY idx_scan DESC;

-- F.5 Table sizes (for partition benefit analysis)
SELECT
    n.nspname                                        AS schema_name,
    c.relname                                        AS table_name,
    pg_size_pretty(pg_relation_size(c.oid))          AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid))           AS indexes_size,
    pg_size_pretty(pg_total_relation_size(c.oid))    AS total_size,
    c.reltuples::bigint                              AS estimated_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'dsis'
  AND c.relkind IN ('r', 'p')
ORDER BY pg_total_relation_size(c.oid) DESC;

-- ============================================================================================================================
-- PART G — SECURITY & COMPLIANCE QUERIES
-- ============================================================================================================================

-- G.1 Failed login attempts in last 24 hours (brute force detection)
SELECT
    u.username,
    u.email,
    u.login_attempt_count,
    u.account_locked_at,
    u.last_login_at,
    COUNT(al.audit_id) FILTER (WHERE al.status = 'denied' AND al.action = 'LOGIN') AS failed_logins_24h
FROM dsis.users u
LEFT JOIN dsis.audit_log al ON al.user_id = u.user_id
                             AND al.logged_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
WHERE u.login_attempt_count > 0
   OR u.account_locked_at IS NOT NULL
GROUP BY u.user_id, u.username, u.email, u.login_attempt_count,
         u.account_locked_at, u.last_login_at
ORDER BY failed_logins_24h DESC, u.login_attempt_count DESC;

-- G.2 Evidence chain-of-custody integrity check
SELECT
    es.evidence_id,
    es.file_name,
    es.evidence_type,
    es.checksum_sha256,
    es.is_encrypted,
    es.collected_at,
    es.retention_until,
    jsonb_array_length(es.chain_of_custody) AS custody_entries,
    ir.incident_ref
FROM dsis.evidence_storage es
JOIN dsis.incident_reports ir ON ir.incident_id = es.incident_id
WHERE es.is_encrypted = FALSE   -- flag unencrypted evidence
   OR es.checksum_sha256 IS NULL -- flag missing integrity hash
ORDER BY es.collected_at;

-- G.3 Dormant accounts (no login in 90 days — security risk)
SELECT
    u.username,
    u.full_name,
    u.email,
    r.role_name,
    u.status,
    u.last_login_at,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - u.last_login_at) AS days_since_login
FROM dsis.users u
JOIN dsis.roles r ON r.role_id = u.role_id
WHERE u.status = 'active'
  AND (u.last_login_at < CURRENT_TIMESTAMP - INTERVAL '90 days'
       OR u.last_login_at IS NULL)
ORDER BY days_since_login DESC NULLS FIRST;

-- G.4 Critical data changes in last 48 hours (audit trail review)
SELECT
    al.logged_at,
    u.username,
    r.role_name,
    al.action,
    al.table_name,
    al.record_id,
    al.ip_address,
    al.status
FROM dsis.audit_log al
LEFT JOIN dsis.users u ON u.user_id = al.user_id
LEFT JOIN dsis.roles r ON r.role_id = u.role_id
WHERE al.logged_at >= CURRENT_TIMESTAMP - INTERVAL '48 hours'
  AND al.action IN ('DELETE', 'SCHEMA_CHANGE', 'PERMISSION_CHANGE')
ORDER BY al.logged_at DESC;

-- ============================================================================================================================
-- PART H — UTILITY & MAINTENANCE QUERIES
-- ============================================================================================================================

-- H.1 Refresh materialized view (run nightly via pg_cron or cron job)
REFRESH MATERIALIZED VIEW CONCURRENTLY dsis.mvw_monthly_alert_trend;

-- H.2 UPSERT: Update live location tracking (called by telemetry ingest service)
INSERT INTO dsis.live_location_tracking (
    drone_id, mission_id, latitude, longitude,
    altitude_m, heading_deg, speed_kmh, battery_pct, is_online, updated_at
)
SELECT
    d.drone_id,
    fm.mission_id,
    33.7310, 73.0942,
    85.5, 165.3, 42.7, 72,
    TRUE, CURRENT_TIMESTAMP
FROM dsis.drones d
LEFT JOIN dsis.flight_missions fm
    ON fm.drone_id = d.drone_id AND fm.status = 'in_progress'
WHERE d.serial_number = 'SN-DJI-M30T-001'
ON CONFLICT (drone_id)
DO UPDATE SET
    mission_id  = EXCLUDED.mission_id,
    latitude    = EXCLUDED.latitude,
    longitude   = EXCLUDED.longitude,
    altitude_m  = EXCLUDED.altitude_m,
    heading_deg = EXCLUDED.heading_deg,
    speed_kmh   = EXCLUDED.speed_kmh,
    battery_pct = EXCLUDED.battery_pct,
    is_online   = EXCLUDED.is_online,
    updated_at  = EXCLUDED.updated_at;

-- H.3 Database health dashboard query
SELECT
    'Schema Tables'    AS metric, COUNT(*)::text AS value
    FROM pg_tables WHERE schemaname = 'dsis'
UNION ALL
SELECT 'Active Users',      COUNT(*)::text FROM dsis.users      WHERE status = 'active'
UNION ALL
SELECT 'Active Drones',     COUNT(*)::text FROM dsis.drones     WHERE is_active = TRUE
UNION ALL
SELECT 'Active Zones',      COUNT(*)::text FROM dsis.surveillance_zones WHERE is_active = TRUE
UNION ALL
SELECT 'Open Alerts',       COUNT(*)::text FROM dsis.alerts     WHERE status = 'open'
UNION ALL
SELECT 'Open Incidents',    COUNT(*)::text FROM dsis.incident_reports WHERE status NOT IN ('resolved','archived')
UNION ALL
SELECT 'Total Indexes',     COUNT(*)::text FROM pg_indexes       WHERE schemaname = 'dsis'
UNION ALL
SELECT 'DB Total Size',     pg_size_pretty(SUM(pg_total_relation_size(c.oid)))
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'dsis';

-- ============================================================================================================================
-- END OF phase2_queries.sql
-- ============================================================================================================================
-- QUERY CATEGORIES IMPLEMENTED:
--   A. CRUD           : 15 queries  (INSERT, SELECT, UPDATE, DELETE with real business logic)
--   B. Aggregation    :  5 queries  (GROUP BY, HAVING, FILTER, date trunc)
--   C. Analytical     :  6 queries  (CTE, window functions, LAG/LEAD, recursive CTE, 6-table JOIN)
--   D. Subqueries     :  5 queries  (correlated, scalar, IN, EXISTS, LATERAL)
--   E. RBAC           :  5 queries  (permission check, matrix, escalation detection, RLS verify)
--   F. Performance    :  5 queries  (EXPLAIN ANALYZE indexed vs non-indexed, index stats, sizes)
--   G. Security       :  4 queries  (brute force, evidence integrity, dormant accounts, audit)
--   H. Utilities      :  3 queries  (materialized view refresh, UPSERT, DB health)
-- ============================================================================================================================
