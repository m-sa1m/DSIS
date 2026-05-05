const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createIncidentSchema, updateIncidentSchema, updateIncidentStatusSchema } = require('../schemas/incidents.schema');
const controller = require('../controllers/incidents.controller');

router.get('/', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getAll);
router.get('/:id', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getById);
router.post('/', auth, rbac(['Admin', 'Operator', 'Analyst']), validate(createIncidentSchema), controller.create);
router.put('/:id', auth, rbac(['Admin', 'Operator', 'Analyst']), validate(updateIncidentSchema), controller.update);
router.put('/:id/status', auth, rbac(['Admin', 'Operator', 'Analyst']), validate(updateIncidentStatusSchema), controller.updateStatus);
router.delete('/:id', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.remove);

module.exports = router;
