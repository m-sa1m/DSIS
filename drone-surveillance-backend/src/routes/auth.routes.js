const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validate');
const { loginSchema } = require('../schemas/auth.schema');
const controller = require('../controllers/auth.controller');

router.post('/login', validate(loginSchema), controller.login);
router.post('/logout', auth, controller.logout);
router.get('/me', auth, controller.me);

module.exports = router;
