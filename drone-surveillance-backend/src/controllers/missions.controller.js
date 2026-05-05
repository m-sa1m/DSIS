const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fm.*, d.drone_name, sz.zone_name, u.full_name AS operator_name
       FROM flight_missions fm
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       LEFT JOIN users u ON fm.operator_id = u.user_id
       ORDER BY fm.scheduled_time DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fm.*, d.drone_name, sz.zone_name, u.full_name AS operator_name
       FROM flight_missions fm
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       LEFT JOIN users u ON fm.operator_id = u.user_id
       WHERE fm.mission_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Mission not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function getByDrone(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT fm.*, d.drone_name, sz.zone_name, u.full_name AS operator_name
       FROM flight_missions fm
       LEFT JOIN drones d ON fm.drone_id = d.drone_id
       LEFT JOIN surveillance_zones sz ON fm.zone_id = sz.zone_id
       LEFT JOIN users u ON fm.operator_id = u.user_id
       WHERE fm.drone_id = $1
       ORDER BY fm.scheduled_time DESC`,
      [req.params.droneId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { drone_id, zone_id, operator_id, scheduled_time, mission_status, notes } = req.body;
    const result = await pool.query(
      `INSERT INTO flight_missions (drone_id, zone_id, operator_id, scheduled_time, mission_status, notes)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [drone_id, zone_id, operator_id, scheduled_time, mission_status || 'Scheduled', notes || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { drone_id, zone_id, operator_id, scheduled_time, mission_status, notes } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (drone_id !== undefined) { fields.push(`drone_id = $${idx++}`); values.push(drone_id); }
    if (zone_id !== undefined) { fields.push(`zone_id = $${idx++}`); values.push(zone_id); }
    if (operator_id !== undefined) { fields.push(`operator_id = $${idx++}`); values.push(operator_id); }
    if (scheduled_time !== undefined) { fields.push(`scheduled_time = $${idx++}`); values.push(scheduled_time); }
    if (mission_status !== undefined) { fields.push(`mission_status = $${idx++}`); values.push(mission_status); }
    if (notes !== undefined) { fields.push(`notes = $${idx++}`); values.push(notes); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE flight_missions SET ${fields.join(', ')} WHERE mission_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Mission not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query('DELETE FROM flight_missions WHERE mission_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Mission not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, getByDrone, create, update, remove };
