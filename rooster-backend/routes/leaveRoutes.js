const express = require('express');
const router = express.Router();
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const leaveController = require('../controllers/leave-controller');
const { authenticateToken } = require('../middleware/auth');
const { validateLeaveRequest, handleValidationErrors } = require('../middleware/security');

// Simple endpoints that don't require company context (for testing)
router.post('/simple/apply', authenticateToken, async (req, res) => {
  try {
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Simple apply endpoint - Request body:', req.body);
    console.log('DEBUG: Simple apply endpoint - User:', req.user);
    console.log('DEBUG: Simple apply endpoint - Company ID:', companyId);
    console.log('DEBUG: Simple apply endpoint - Headers:', req.headers);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Basic validation for simple endpoint
    const { leaveType, startDate, endDate, reason } = req.body;
    
    if (!leaveType || !startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Leave type, start date, and end date are required'
      });
    }

    // Validate dates
    const start = new Date(startDate);
    const end = new Date(endDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (start < today) {
      return res.status(400).json({
        success: false,
        message: 'Start date cannot be in the past'
      });
    }
    
    if (end < start) {
      return res.status(400).json({
        success: false,
        message: 'End date cannot be before start date'
      });
    }

    // Validate reason length (make it optional but if provided, must be reasonable)
    if (reason && reason.trim().length > 500) {
      return res.status(400).json({
        success: false,
        message: 'Reason must be less than 500 characters'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Simple apply endpoint - Final req.companyId:', req.companyId);
    
    const result = await leaveController.applyLeave(req, res);
  } catch (error) {
    console.error('DEBUG: Simple apply endpoint - Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error applying leave',
      error: error.message
    });
  }
});

router.get('/simple/history', authenticateToken, async (req, res) => {
  try {
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    const result = await leaveController.getLeaveHistory(req, res);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching leave history',
      error: error.message
    });
  }
});

// Simple endpoint for getting all leave requests (for admin)
router.get('/simple/leave-requests', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple leave-requests endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling getAllLeaveRequests with companyId:', req.companyId);
    const result = await leaveController.getAllLeaveRequests(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple leave-requests endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave requests',
      error: error.message
    });
  }
});

// Simple endpoint for approving leave requests
router.put('/simple/:id/approve', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple approve endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling approveLeaveRequest with companyId:', req.companyId);
    const result = await leaveController.approveLeaveRequest(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple approve endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error approving leave request',
      error: error.message
    });
  }
});

// Simple endpoint for rejecting leave requests
router.put('/simple/:id/reject', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple reject endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling rejectLeaveRequest with companyId:', req.companyId);
    const result = await leaveController.rejectLeaveRequest(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple reject endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error rejecting leave request',
      error: error.message
    });
  }
});

// Simple endpoint for canceling leave requests
router.delete('/simple/:id', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple cancel endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling cancelLeaveRequest with companyId:', req.companyId);
    const result = await leaveController.cancelLeaveRequest(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple cancel endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error canceling leave request',
      error: error.message
    });
  }
});

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
