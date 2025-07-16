const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const analyticsController = require('../controllers/analytics-controller');

// Employee Analytics endpoints
router.get('/attendance/:userId', authenticateToken, analyticsController.getAttendanceAnalytics);
router.get('/work-hours/:userId', authenticateToken, analyticsController.getWorkHoursAnalytics);
router.get('/summary/:userId', analyticsController.getAnalyticsSummary);
router.get('/late-checkins/:userId', authenticateToken, analyticsController.getLateCheckins);
router.get('/avg-checkout/:userId', authenticateToken, analyticsController.getAverageCheckoutTime);
router.get('/recent-activity/:userId', authenticateToken, analyticsController.getRecentActivity);
router.get('/leave-types-breakdown', authenticateToken, analyticsController.getLeaveTypesBreakdown);

// Admin Analytics endpoints
router.get('/admin/overview', authenticateToken, analyticsController.getAdminOverview);

// admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

router.get('/summary', authenticateToken, adminOnly, analyticsController.getSummary);

// Admin leave types breakdown (after adminOnly defined)
router.get('/admin/leave-types-breakdown', authenticateToken, adminOnly, analyticsController.getLeaveTypesBreakdownAdmin);
router.get('/admin/monthly-hours-trend', authenticateToken, adminOnly, analyticsController.getMonthlyHoursTrendAdmin);

// Payroll analytics
router.get('/admin/payroll-trend', authenticateToken, adminOnly, analyticsController.getPayrollTrendAdmin);
router.get('/admin/payroll-deductions-breakdown', authenticateToken, adminOnly, analyticsController.getPayrollDeductionsBreakdownAdmin);

// Report generation
router.get('/admin/generate-report', authenticateToken, adminOnly, analyticsController.generateReport);

// Add endpoint for all active employees and admins (for Total Employees modal)
router.get('/admin/active-users', authenticateToken, analyticsController.getActiveUsersList);

module.exports = router; 