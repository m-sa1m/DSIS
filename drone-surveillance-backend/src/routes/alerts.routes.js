const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { updateAlertSchema } = require('../schemas/alerts.schema');
const controller = require('../controllers/alerts.controller');

router.get('/', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getAll);
router.get('/:id', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getById);
router.put('/:id', auth, rbac(['Admin']), validate(updateAlertSchema), controller.update);

module.exports = router;
