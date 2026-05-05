const pool = require('../config/db');

async function droneUtilization(req, res, next) {
  try {
    const result = await pool.query('SELECT * FROM get_drone_utilization_report()');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function alertTrends(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT
         TO_CHAR(a.generated_at, 'YYYY-MM') AS month,
         a.severity,
         COUNT(*)::int AS alert_count
       FROM alerts a
       WHERE EXTRACT(YEAR FROM a.generated_at) = EXTRACT(YEAR FROM CURRENT_DATE)
       GROUP BY TO_CHAR(a.generated_at, 'YYYY-MM'), a.severity
       ORDER BY month, a.severity`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function highRiskZones(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT
         sz.zone_id,
         sz.zone_name,
         sz.risk_level,
         COUNT(det.detection_id)::int AS high_detection_count
       FROM surveillance_zones sz
       LEFT JOIN flight_missions fm ON sz.zone_id = fm.zone_id
       LEFT JOIN flight_logs fl ON fm.mission_id = fl.mission_id
       LEFT JOIN detected_objects det ON fl.log_id = det.log_id AND det.threat_level = 'High'
       GROUP BY sz.zone_id, sz.zone_name, sz.risk_level
       ORDER BY high_detection_count DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function operatorPerformance(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT
         u.user_id,
         u.full_name,
         COUNT(fm.mission_id)::int AS completed_missions
       FROM users u
       JOIN flight_missions fm ON u.user_id = fm.operator_id
       WHERE fm.mission_status = 'Completed'
       GROUP BY u.user_id, u.full_name
       ORDER BY completed_missions DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

module.exports = { droneUtilization, alertTrends, highRiskZones, operatorPerformance };
