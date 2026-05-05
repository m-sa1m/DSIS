function rbac(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !req.user.role_name) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }
    if (!allowedRoles.includes(req.user.role_name)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    next();
  };
}

module.exports = rbac;
