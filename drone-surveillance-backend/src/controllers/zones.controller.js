const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const result = await pool.query('SELECT * FROM surveillance_zones ORDER BY zone_id');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const result = await pool.query('SELECT * FROM surveillance_zones WHERE zone_id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Zone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { zone_name, location_description, risk_level, coordinates_lat, coordinates_lng } = req.body;
    const result = await pool.query(
      `INSERT INTO surveillance_zones (zone_name, location_description, risk_level, coordinates_lat, coordinates_lng)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [zone_name, location_description || null, risk_level || 'Low', coordinates_lat || null, coordinates_lng || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { zone_name, location_description, risk_level, coordinates_lat, coordinates_lng } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (zone_name !== undefined) { fields.push(`zone_name = $${idx++}`); values.push(zone_name); }
    if (location_description !== undefined) { fields.push(`location_description = $${idx++}`); values.push(location_description); }
    if (risk_level !== undefined) { fields.push(`risk_level = $${idx++}`); values.push(risk_level); }
    if (coordinates_lat !== undefined) { fields.push(`coordinates_lat = $${idx++}`); values.push(coordinates_lat); }
    if (coordinates_lng !== undefined) { fields.push(`coordinates_lng = $${idx++}`); values.push(coordinates_lng); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE surveillance_zones SET ${fields.join(', ')} WHERE zone_id = $${idx} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Zone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const result = await pool.query('DELETE FROM surveillance_zones WHERE zone_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Zone not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll, getById, create, update, remove };
