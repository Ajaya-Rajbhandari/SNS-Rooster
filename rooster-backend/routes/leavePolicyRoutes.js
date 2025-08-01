const express = require('express');
const router = express.Router();
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const leavePolicyController = require('../controllers/leave-policy-controller');
const { authenticateToken } = require('../middleware/auth');

// Test endpoint to check authentication and company context
router.get('/test-auth', authenticateToken, (req, res) => {
  res.json({
    success: true,
    user: req.user,
    companyId: req.user?.companyId,
    headers: {
      'x-company-id': req.headers['x-company-id'],
      authorization: req.headers.authorization ? 'Bearer [HIDDEN]' : 'Not provided'
    }
  });
});

// Simple endpoints that don't require company context (for testing)
router.get('/simple', authenticateToken, async (req, res) => {
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

    const policies = await leavePolicyController.getLeavePolicies(req, res);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching policies',
      error: error.message
    });
  }
});

router.get('/simple/default', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple default policy endpoint hit');
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

    console.log('DEBUG: Calling getDefaultPolicy with companyId:', req.companyId);
    const policy = await leavePolicyController.getDefaultPolicy(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple default policy endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching default policy',
      error: error.message
    });
  }
});

router.post('/simple', authenticateToken, async (req, res) => {
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
    
    const result = await leavePolicyController.createLeavePolicy(req, res);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating policy',
      error: error.message
    });
  }
});

router.delete('/simple/:id', authenticateToken, async (req, res) => {
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
    
    const result = await leavePolicyController.deleteLeavePolicy(req, res);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting policy',
      error: error.message
    });
  }
});

// Apply company context middleware to all routes
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);

// ===== LEAVE POLICY MANAGEMENT =====

// Get all leave policies for the company
router.get('/', authenticateToken, leavePolicyController.getLeavePolicies);

// Get default leave policy for the company
router.get('/default', authenticateToken, leavePolicyController.getDefaultPolicy);

// Create new leave policy
router.post('/', authenticateToken, leavePolicyController.createLeavePolicy);

// Update leave policy
router.put('/:id', authenticateToken, leavePolicyController.updateLeavePolicy);

// Delete leave policy
router.delete('/:id', authenticateToken, leavePolicyController.deleteLeavePolicy);

// Calculate leave balance for employee based on policy
router.get('/balance/:employeeId', authenticateToken, leavePolicyController.calculateLeaveBalance);

module.exports = router; 