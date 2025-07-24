const express = require('express');
const router = express.Router();
const TrialService = require('../services/trialService');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext } = require('../middleware/companyContext');

// Get trial status for current company (admin only)
router.get('/status', authenticateToken, authorizeRoles('admin'), validateCompanyContext, async (req, res) => {
  try {
    const trialStatus = await TrialService.getTrialStatus(req.companyId);
    res.json({
      success: true,
      trialStatus
    });
  } catch (error) {
    console.error('Error getting trial status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get trial status',
      message: error.message
    });
  }
});

// Check all trial companies (super admin only)
router.get('/check-all', authenticateToken, authorizeRoles('super_admin'), async (req, res) => {
  try {
    const result = await TrialService.checkTrialStatus();
    res.json({
      success: true,
      result
    });
  } catch (error) {
    console.error('Error checking trial status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to check trial status',
      message: error.message
    });
  }
});

// Activate a company (super admin only)
router.post('/activate/:companyId', authenticateToken, authorizeRoles('super_admin'), async (req, res) => {
  try {
    const { companyId } = req.params;
    const activatedBy = req.user.userId;

    const result = await TrialService.activateCompany(companyId, activatedBy);
    res.json(result);
  } catch (error) {
    console.error('Error activating company:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to activate company',
      message: error.message
    });
  }
});

// Extend trial for a company (super admin only)
router.post('/extend/:companyId', authenticateToken, authorizeRoles('super_admin'), async (req, res) => {
  try {
    const { companyId } = req.params;
    const { additionalDays } = req.body;
    const extendedBy = req.user.userId;

    if (!additionalDays || additionalDays <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid additional days',
        message: 'Additional days must be a positive number'
      });
    }

    const result = await TrialService.extendTrial(companyId, additionalDays, extendedBy);
    res.json(result);
  } catch (error) {
    console.error('Error extending trial:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to extend trial',
      message: error.message
    });
  }
});

// Get trial status for any company (super admin only)
router.get('/status/:companyId', authenticateToken, authorizeRoles('super_admin'), async (req, res) => {
  try {
    const { companyId } = req.params;
    const trialStatus = await TrialService.getTrialStatus(companyId);
    res.json({
      success: true,
      trialStatus
    });
  } catch (error) {
    console.error('Error getting trial status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get trial status',
      message: error.message
    });
  }
});

module.exports = router; 