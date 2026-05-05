const router = require('express').Router();
const auth = require('../middleware/auth');
const rbac = require('../middleware/rbac');
const controller = require('../controllers/reports.controller');

router.use(auth, rbac(['Admin', 'Analyst']));

router.get('/drone-utilization', controller.droneUtilization);
router.get('/alert-trends', controller.alertTrends);
router.get('/high-risk-zones', controller.highRiskZones);
router.get('/operator-performance', controller.operatorPerformance);

module.exports = router;
