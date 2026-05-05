const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createZoneSchema, updateZoneSchema } = require('../schemas/zones.schema');
const controller = require('../controllers/zones.controller');

router.use(auth, rbac(['Admin', 'Operator']));

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.post('/', validate(createZoneSchema), controller.create);
router.put('/:id', validate(updateZoneSchema), controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
