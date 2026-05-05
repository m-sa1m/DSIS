const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createLogSchema, updateLogSchema } = require('../schemas/logs.schema');
const controller = require('../controllers/logs.controller');

router.use(auth, rbac(['Admin', 'Operator']));

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.get('/mission/:missionId', controller.getByMission);
router.post('/', validate(createLogSchema), controller.create);
router.put('/:id', validate(updateLogSchema), controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
