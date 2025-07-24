const express = require('express');
const router = express.Router();
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const leaveController = require('../controllers/leave-controller');
const { authenticateToken } = require('../middleware/auth');

// Apply company context middleware to all routes
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);

// Apply for leave
router.post('/apply', authenticateToken, leaveController.applyLeave);

// Get leave history for employee
router.get('/history', authenticateToken, leaveController.getLeaveHistory);

// Get all leave requests for admin
router.get('/leave-requests', authenticateToken, leaveController.getAllLeaveRequests);

// Approve or reject a leave request
router.put('/:id/approve', authenticateToken, leaveController.approveLeaveRequest);
router.put('/:id/reject', authenticateToken, leaveController.rejectLeaveRequest);

module.exports = router;
