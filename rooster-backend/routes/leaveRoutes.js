const express = require('express');
const router = express.Router();
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const leaveController = require('../controllers/leave-controller');
const { authenticateToken } = require('../middleware/auth');
const { validateLeaveRequest, handleValidationErrors } = require('../middleware/security');

// Apply company context middleware to all routes
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);

// ===== BASIC LEAVE OPERATIONS =====

// Apply for leave
router.post('/apply', authenticateToken, validateLeaveRequest, handleValidationErrors, leaveController.applyLeave);

// Get leave history for employee
router.get('/history', authenticateToken, leaveController.getLeaveHistory);

// Get all leave requests for admin
router.get('/leave-requests', authenticateToken, leaveController.getAllLeaveRequests);

// Approve or reject a leave request
router.put('/:id/approve', authenticateToken, leaveController.approveLeaveRequest);
router.put('/:id/reject', authenticateToken, leaveController.rejectLeaveRequest);

// ===== PHASE 2 ENHANCED FEATURES =====

// Get leave policies for the company
router.get('/policies', authenticateToken, leaveController.getLeavePolicies);

// Get leave calendar data for a specific month
router.get('/calendar', authenticateToken, leaveController.getLeaveCalendar);

// Bulk approve/reject leave requests
router.put('/bulk-update', authenticateToken, leaveController.bulkUpdateLeaveRequests);

// Get leave statistics and analytics
router.get('/statistics', authenticateToken, leaveController.getLeaveStatistics);

// Cancel leave request (for employees)
router.delete('/:id/cancel', authenticateToken, leaveController.cancelLeaveRequest);

module.exports = router;
