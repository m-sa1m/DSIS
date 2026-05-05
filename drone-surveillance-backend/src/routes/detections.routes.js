const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createDetectionSchema, updateDetectionSchema } = require('../schemas/detections.schema');
const controller = require('../controllers/detections.controller');

router.get('/', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getAll);
router.get('/:id', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getById);
router.get('/log/:logId', auth, rbac(['Admin', 'Operator', 'Analyst']), controller.getByLog);
router.post('/', auth, rbac(['Admin', 'Operator']), validate(createDetectionSchema), controller.create);
router.put('/:id', auth, rbac(['Admin', 'Operator']), validate(updateDetectionSchema), controller.update);
router.delete('/:id', auth, rbac(['Admin', 'Operator']), controller.remove);

module.exports = router;
