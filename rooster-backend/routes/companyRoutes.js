const express = require('express');
const router = express.Router();
const Company = require('../models/Company');
const { 
  resolveCompanyContext, 
  requireCompanyContext, 
  validateFeatureAccess,
  validateCompanyOwnership 
} = require('../middleware/companyContext');
const auth = require('../middleware/auth');

/**
 * @route   GET /api/company/resolve
 * @desc    Resolve company by domain or subdomain
 * @access  Public
 */
router.get('/resolve', async (req, res) => {
  try {
    const { domain, subdomain } = req.query;
    let company = null;

    if (domain) {
      company = await Company.findByDomain(domain);
    } else if (subdomain) {
      company = await Company.findBySubdomain(subdomain);
    }

    if (!company) {
      return res.status(404).json({
        error: 'Company not found',
        message: 'No company found with the provided domain or subdomain'
      });
    }

    if (!company.isActive()) {
      return res.status(403).json({
        error: 'Company inactive',
        message: 'This company account is not active'
      });
    }

    // Return company context (public information only)
    res.json({
      success: true,
      company: company.getCompanyContext()
    });
  } catch (error) {
    console.error('Error resolving company:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to resolve company'
    });
  }
});

/**
 * @route   GET /api/company/context
 * @desc    Get current company context
 * @access  Private (requires authentication)
 */
router.get('/context', auth, resolveCompanyContext, requireCompanyContext, (req, res) => {
  try {
    res.json({
      success: true,
      company: req.company.getCompanyContext()
    });
  } catch (error) {
    console.error('Error getting company context:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get company context'
    });
  }
});

/**
 * @route   GET /api/company/features
 * @desc    Get company features
 * @access  Private (requires authentication)
 */
router.get('/features', auth, resolveCompanyContext, requireCompanyContext, (req, res) => {
  try {
    res.json({
      success: true,
      features: req.company.features
    });
  } catch (error) {
    console.error('Error getting company features:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get company features'
    });
  }
});

/**
 * @route   GET /api/company/settings
 * @desc    Get company settings
 * @access  Private (requires authentication and admin role)
 */
router.get('/settings', auth, resolveCompanyContext, requireCompanyContext, (req, res) => {
  try {
    // Only admins can access company settings
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can access company settings'
      });
    }

    res.json({
      success: true,
      settings: req.company.settings,
      branding: req.company.branding,
      limits: req.company.limits
    });
  } catch (error) {
    console.error('Error getting company settings:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get company settings'
    });
  }
});

/**
 * @route   PUT /api/company/settings
 * @desc    Update company settings
 * @access  Private (requires authentication and admin role)
 */
router.put('/settings', auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
  try {
    // Only admins can update company settings
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can update company settings'
      });
    }

    const { settings, branding } = req.body;
    const updateData = {};

    if (settings) {
      updateData.settings = { ...req.company.settings, ...settings };
    }

    if (branding) {
      updateData.branding = { ...req.company.branding, ...branding };
    }

    const updatedCompany = await Company.findByIdAndUpdate(
      req.companyId,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Company settings updated successfully',
      company: updatedCompany.getCompanyContext()
    });
  } catch (error) {
    console.error('Error updating company settings:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update company settings'
    });
  }
});

/**
 * @route   GET /api/company/limits
 * @desc    Get company usage limits and current usage
 * @access  Private (requires authentication and admin role)
 */
router.get('/limits', auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
  try {
    // Only admins can access company limits
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can access company limits'
      });
    }

    const User = require('../models/User');
    const Attendance = require('../models/Attendance');

    // Get current usage
    const employeeCount = await User.countDocuments({ 
      companyId: req.companyId,
      role: 'employee'
    });

    const attendanceCount = await Attendance.countDocuments({ 
      companyId: req.companyId 
    });

    // Calculate storage usage (placeholder - would need actual implementation)
    const storageUsedGB = 0; // This would need to be calculated from file storage

    const limits = req.company.limits;
    const usage = {
      employees: {
        current: employeeCount,
        limit: limits.maxEmployees,
        percentage: Math.round((employeeCount / limits.maxEmployees) * 100)
      },
      storage: {
        current: storageUsedGB,
        limit: limits.maxStorageGB,
        percentage: Math.round((storageUsedGB / limits.maxStorageGB) * 100)
      },
      attendance: {
        current: attendanceCount,
        limit: null // No limit on attendance records
      }
    };

    res.json({
      success: true,
      limits,
      usage
    });
  } catch (error) {
    console.error('Error getting company limits:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get company limits'
    });
  }
});

/**
 * @route   GET /api/company/status
 * @desc    Get company status and subscription information
 * @access  Private (requires authentication and admin role)
 */
router.get('/status', auth, resolveCompanyContext, requireCompanyContext, (req, res) => {
  try {
    // Only admins can access company status
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can access company status'
      });
    }

    const statusInfo = {
      status: req.company.status,
      subscriptionPlan: req.company.subscriptionPlan,
      billingCycle: req.company.billingCycle,
      nextBillingDate: req.company.nextBillingDate,
      trialEndDate: req.company.trialEndDate,
      isActive: req.company.isActive(),
      createdAt: req.company.createdAt,
      updatedAt: req.company.updatedAt
    };

    res.json({
      success: true,
      status: statusInfo
    });
  } catch (error) {
    console.error('Error getting company status:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get company status'
    });
  }
});

/**
 * @route   POST /api/company/validate-feature
 * @desc    Validate if a feature is enabled for the company
 * @access  Private (requires authentication)
 */
router.post('/validate-feature', auth, resolveCompanyContext, requireCompanyContext, (req, res) => {
  try {
    const { featureName } = req.body;

    if (!featureName) {
      return res.status(400).json({
        error: 'Feature name required',
        message: 'Feature name is required for validation'
      });
    }

    const isEnabled = req.company.isFeatureEnabled(featureName);

    res.json({
      success: true,
      feature: featureName,
      enabled: isEnabled
    });
  } catch (error) {
    console.error('Error validating feature:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to validate feature'
    });
  }
});

module.exports = router; 