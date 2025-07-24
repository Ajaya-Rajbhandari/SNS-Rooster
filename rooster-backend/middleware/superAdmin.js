const SuperAdmin = require('../models/SuperAdmin');
const User = require('../models/User');

/**
 * Middleware to check if user is a super admin
 */
const requireSuperAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'User must be authenticated'
      });
    }

    // Check if user has super_admin role
    if (req.user.role !== 'super_admin') {
      return res.status(403).json({
        error: 'Super admin access required',
        message: 'This endpoint requires super admin privileges'
      });
    }

    // Verify super admin record exists and is active
    const superAdmin = await SuperAdmin.findOne({ 
      userId: req.user.userId, 
      isActive: true 
    });

    if (!superAdmin) {
      return res.status(403).json({
        error: 'Super admin access denied',
        message: 'Super admin account is not active or not found'
      });
    }

    // Add super admin info to request
    req.superAdmin = superAdmin;
    next();
  } catch (error) {
    console.error('Super admin middleware error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: 'Error validating super admin access'
    });
  }
};

/**
 * Middleware to check specific super admin permissions
 */
const requirePermission = (permission) => {
  return async (req, res, next) => {
    try {
      if (!req.superAdmin) {
        return res.status(403).json({
          error: 'Super admin access required',
          message: 'Super admin validation must be performed first'
        });
      }

      if (!req.superAdmin.permissions[permission]) {
        return res.status(403).json({
          error: 'Permission denied',
          message: `Super admin does not have ${permission} permission`
        });
      }

      next();
    } catch (error) {
      console.error('Permission middleware error:', error);
      return res.status(500).json({
        error: 'Internal server error',
        message: 'Error checking permissions'
      });
    }
  };
};

/**
 * Middleware to check if user can access company data
 * Super admins can access any company, regular users can only access their own
 */
const validateCompanyAccess = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'User must be authenticated'
      });
    }

    // Super admins can access any company
    if (req.user.role === 'super_admin') {
      return next();
    }

    // Regular users can only access their own company
    if (req.user.companyId && req.companyId) {
      if (req.user.companyId.toString() !== req.companyId) {
        return res.status(403).json({
          error: 'Access denied',
          message: 'You can only access your own company data'
        });
      }
    }

    next();
  } catch (error) {
    console.error('Company access validation error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: 'Error validating company access'
    });
  }
};

module.exports = {
  requireSuperAdmin,
  requirePermission,
  validateCompanyAccess
}; 