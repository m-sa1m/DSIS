const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createUserSchema, updateUserSchema } = require('../schemas/users.schema');
const controller = require('../controllers/users.controller');

router.use(auth, rbac(['Admin']));

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.post('/', validate(createUserSchema), controller.create);
router.put('/:id', validate(updateUserSchema), controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
