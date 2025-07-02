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

// admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

router.get('/summary', authMiddleware, adminOnly, analyticsController.getSummary);

// Admin leave types breakdown (after adminOnly defined)
router.get('/admin/leave-types-breakdown', authMiddleware, adminOnly, analyticsController.getLeaveTypesBreakdownAdmin);
router.get('/admin/monthly-hours-trend', authMiddleware, adminOnly, analyticsController.getMonthlyHoursTrendAdmin);

// Payroll analytics
router.get('/admin/payroll-trend', authMiddleware, adminOnly, analyticsController.getPayrollTrendAdmin);
router.get('/admin/payroll-deductions-breakdown', authMiddleware, adminOnly, analyticsController.getPayrollDeductionsBreakdownAdmin);

module.exports = router; 