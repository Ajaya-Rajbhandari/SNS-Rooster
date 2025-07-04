const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leave-controller');
const auth = require('../middleware/auth');

// Apply for leave
router.post('/apply', auth, leaveController.applyLeave);

// Get leave history for employee
router.get('/history', auth, leaveController.getLeaveHistory);

// Get all leave requests for admin
router.get('/leave-requests', auth, leaveController.getAllLeaveRequests);

// Approve or reject a leave request
router.put('/:id/approve', auth, leaveController.approveLeaveRequest);
router.put('/:id/reject', auth, leaveController.rejectLeaveRequest);

module.exports = router;
