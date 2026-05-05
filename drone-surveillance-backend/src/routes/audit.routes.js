const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const controller = require('../controllers/audit.controller');

router.use(auth, rbac(['Admin']));

router.get('/', controller.getAll);

module.exports = router;
