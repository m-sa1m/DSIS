const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT a.*, det.object_type, det.threat_level, d.drone_name, sz.zone_name
       FROM alerts a
       LEFT JOIN detected_objects det ON a.detection_id = det.detection_id
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       ORDER BY a.generated_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT a.*, det.object_type, det.threat_level, d.drone_name, sz.zone_name
       FROM alerts a
       LEFT JOIN detected_objects det ON a.detection_id = det.detection_id
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       WHERE a.alert_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Alert not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { alert_status, resolved_by } = req.body;
    const resolved_at = alert_status === 'Resolved' ? new Date().toISOString() : null;
    const result = await pool.query(
      `UPDATE alerts SET alert_status = $1, resolved_at = $2, resolved_by = $3
       WHERE alert_id = $4 RETURNING *`,
      [alert_status, resolved_at, resolved_by || null, req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Alert not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, update };
