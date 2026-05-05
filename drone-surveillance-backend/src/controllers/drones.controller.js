const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT d.*, sz.zone_name
       FROM drones d
       LEFT JOIN surveillance_zones sz ON d.zone_id = sz.zone_id
       ORDER BY d.drone_id`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT d.*, sz.zone_name
       FROM drones d
       LEFT JOIN surveillance_zones sz ON d.zone_id = sz.zone_id
       WHERE d.drone_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Drone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { drone_name, model, status, zone_id } = req.body;
    const result = await pool.query(
      `INSERT INTO drones (drone_name, model, status, zone_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [drone_name, model, status || 'Active', zone_id || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { drone_name, model, status, zone_id } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (drone_name !== undefined) { fields.push(`drone_name = $${idx++}`); values.push(drone_name); }
    if (model !== undefined) { fields.push(`model = $${idx++}`); values.push(model); }
    if (status !== undefined) { fields.push(`status = $${idx++}`); values.push(status); }
    if (zone_id !== undefined) { fields.push(`zone_id = $${idx++}`); values.push(zone_id); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE drones SET ${fields.join(', ')} WHERE drone_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Drone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query(
      'DELETE FROM drones WHERE drone_id = $1 RETURNING *',
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Drone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, create, update, remove };
