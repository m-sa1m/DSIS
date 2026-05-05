const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT det.*, fl.mission_id, d.drone_name, sz.zone_name
       FROM detected_objects det
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       ORDER BY det.detected_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT det.*, fl.mission_id, d.drone_name, sz.zone_name
       FROM detected_objects det
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       WHERE det.detection_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Detection not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function getByLog(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT det.*, fl.mission_id, d.drone_name, sz.zone_name
       FROM detected_objects det
       LEFT JOIN flight_logs fl ON det.log_id = fl.log_id
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       WHERE det.log_id = $1
       ORDER BY det.detected_at DESC`,
      [req.params.logId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { log_id, object_type, threat_level, coordinates_lat, coordinates_lng, description } = req.body;
    const result = await pool.query(
      `INSERT INTO detected_objects (log_id, object_type, threat_level, coordinates_lat, coordinates_lng, description)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [log_id, object_type, threat_level, coordinates_lat || null, coordinates_lng || null, description || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { log_id, object_type, threat_level, coordinates_lat, coordinates_lng, description } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (log_id !== undefined) { fields.push(`log_id = $${idx++}`); values.push(log_id); }
    if (object_type !== undefined) { fields.push(`object_type = $${idx++}`); values.push(object_type); }
    if (threat_level !== undefined) { fields.push(`threat_level = $${idx++}`); values.push(threat_level); }
    if (coordinates_lat !== undefined) { fields.push(`coordinates_lat = $${idx++}`); values.push(coordinates_lat); }
    if (coordinates_lng !== undefined) { fields.push(`coordinates_lng = $${idx++}`); values.push(coordinates_lng); }
    if (description !== undefined) { fields.push(`description = $${idx++}`); values.push(description); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE detected_objects SET ${fields.join(', ')} WHERE detection_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Detection not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query('DELETE FROM detected_objects WHERE detection_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Detection not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, getByLog, create, update, remove };
