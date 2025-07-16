const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leave-controller');
const { authenticateToken } = require('../middleware/auth');

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
