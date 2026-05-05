const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fl.*, fm.mission_status, d.drone_name, sz.zone_name
       FROM flight_logs fl
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       ORDER BY fl.start_time DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fl.*, fm.mission_status, d.drone_name, sz.zone_name
       FROM flight_logs fl
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       WHERE fl.log_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Flight log not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function getByMission(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fl.*, fm.mission_status, d.drone_name, sz.zone_name
       FROM flight_logs fl
       LEFT JOIN flight_missions fm ON fl.mission_id = fm.mission_id
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       WHERE fl.mission_id = $1
       ORDER BY fl.start_time DESC`,
      [req.params.missionId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { mission_id, start_time, end_time, duration_minutes, start_lat, start_lng, end_lat, end_lng } = req.body;
    const result = await pool.query(
      `INSERT INTO flight_logs (mission_id, start_time, end_time, duration_minutes, start_lat, start_lng, end_lat, end_lng)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [mission_id, start_time, end_time || null, duration_minutes || null, start_lat || null, start_lng || null, end_lat || null, end_lng || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { mission_id, start_time, end_time, duration_minutes, start_lat, start_lng, end_lat, end_lng } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (mission_id !== undefined) { fields.push(`mission_id = $${idx++}`); values.push(mission_id); }
    if (start_time !== undefined) { fields.push(`start_time = $${idx++}`); values.push(start_time); }
    if (end_time !== undefined) { fields.push(`end_time = $${idx++}`); values.push(end_time); }
    if (duration_minutes !== undefined) { fields.push(`duration_minutes = $${idx++}`); values.push(duration_minutes); }
    if (start_lat !== undefined) { fields.push(`start_lat = $${idx++}`); values.push(start_lat); }
    if (start_lng !== undefined) { fields.push(`start_lng = $${idx++}`); values.push(start_lng); }
    if (end_lat !== undefined) { fields.push(`end_lat = $${idx++}`); values.push(end_lat); }
    if (end_lng !== undefined) { fields.push(`end_lng = $${idx++}`); values.push(end_lng); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE flight_logs SET ${fields.join(', ')} WHERE log_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Flight log not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query('DELETE FROM flight_logs WHERE log_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Flight log not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, getByMission, create, update, remove };
