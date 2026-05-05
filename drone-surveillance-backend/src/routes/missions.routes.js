const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const validate = require('../middleware/validate');
const { createMissionSchema, updateMissionSchema } = require('../schemas/missions.schema');
const controller = require('../controllers/missions.controller');

router.use(auth, rbac(['Admin', 'Operator']));

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.get('/drone/:droneId', controller.getByDrone);
router.post('/', validate(createMissionSchema), controller.create);
router.put('/:id', validate(updateMissionSchema), controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
