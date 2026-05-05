const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createDroneSchema, updateDroneSchema } = require('../schemas/drones.schema');
const controller = require('../controllers/drones.controller');

router.use(auth, rbac(['Admin', 'Operator']));

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.post('/', validate(createDroneSchema), controller.create);
router.put('/:id', validate(updateDroneSchema), controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
