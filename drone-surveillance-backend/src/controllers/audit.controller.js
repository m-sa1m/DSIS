const pool = require('../config/db');

async function getAll(req, res, next) {
  try {
    const { userId } = req.query;
    let query = `
      SELECT al.*, u.full_name
      FROM audit_log al
      LEFT JOIN users u ON al.user_id = u.user_id
    `;
    const values = [];

    if (userId) {
      query += ' WHERE al.user_id = $1';
      values.push(userId);
    }

    query += ' ORDER BY al.performed_at DESC';

    const result = await pool.query(query, values);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAll };
