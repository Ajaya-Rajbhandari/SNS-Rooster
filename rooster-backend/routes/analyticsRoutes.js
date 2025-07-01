const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const analyticsController = require('../controllers/analytics-controller');

// Employee Analytics endpoints
router.get('/attendance/:userId', authMiddleware, analyticsController.getAttendanceAnalytics);
router.get('/work-hours/:userId', authMiddleware, analyticsController.getWorkHoursAnalytics);
router.get('/summary/:userId', analyticsController.getAnalyticsSummary);
router.get('/late-checkins/:userId', authMiddleware, analyticsController.getLateCheckins);
router.get('/avg-checkout/:userId', authMiddleware, analyticsController.getAverageCheckoutTime);
router.get('/recent-activity/:userId', authMiddleware, analyticsController.getRecentActivity);
router.get('/leave-types-breakdown', authMiddleware, analyticsController.getLeaveTypesBreakdown);

// Admin Analytics endpoints
router.get('/admin/overview', authMiddleware, analyticsController.getAdminOverview);

module.exports = router; 