const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT ir.*, a.severity, a.alert_status, det.object_type, det.threat_level,
              sz.zone_name, u.full_name AS reporter_name
       FROM incident_reports ir
       LEFT JOIN alerts a ON ir.alert_id = a.alert_id
       LEFT JOIN detected_objects det ON a.detection_id = det.detection_id
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       LEFT JOIN users u ON ir.reported_by = u.user_id
       ORDER BY ir.created_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT ir.*, a.severity, a.alert_status, det.object_type, det.threat_level,
              sz.zone_name, u.full_name AS reporter_name
       FROM incident_reports ir
       LEFT JOIN alerts a ON ir.alert_id = a.alert_id
       LEFT JOIN detected_objects det ON a.detection_id = det.detection_id
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       LEFT JOIN users u ON ir.reported_by = u.user_id
       WHERE ir.incident_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Incident not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { alert_id, reported_by, title, description, incident_status } = req.body;
    const result = await pool.query(
      `INSERT INTO incident_reports (alert_id, reported_by, title, description, incident_status)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [alert_id, reported_by, title, description || null, incident_status || 'Open']
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { alert_id, reported_by, title, description, incident_status } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (alert_id !== undefined) { fields.push(`alert_id = $${idx++}`); values.push(alert_id); }
    if (reported_by !== undefined) { fields.push(`reported_by = $${idx++}`); values.push(reported_by); }
    if (title !== undefined) { fields.push(`title = $${idx++}`); values.push(title); }
    if (description !== undefined) { fields.push(`description = $${idx++}`); values.push(description); }
    if (incident_status !== undefined) { fields.push(`incident_status = $${idx++}`); values.push(incident_status); }
    fields.push(`updated_at = NOW()`);

    if (fields.length <= 1) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE incident_reports SET ${fields.join(', ')} WHERE incident_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Incident not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const { incident_status } = req.body;
    const userId = req.user.user_id;
    await pool.query('CALL update_incident_status($1, $2, $3)', [
      parseInt(req.params.id, 10),
      incident_status,
      userId,
    ]);
    const result = await pool.query('SELECT * FROM incident_reports WHERE incident_id = $1', [req.params.id]);
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query('DELETE FROM incident_reports WHERE incident_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Incident not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, create, update, updateStatus, remove };
