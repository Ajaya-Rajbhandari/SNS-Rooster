const Company = require('../models/Company');

/**
 * Middleware to validate and set company context
 * This ensures all requests have proper company isolation
 */
const validateCompanyContext = async (req, res, next) => {
  try {
    // Get company context from different possible sources
    // Priority: 1. Authenticated user's companyId, 2. Headers, 3. Query, 4. Body, 5. Params
    const companyId = req.user?.companyId || 
                     req.headers['x-company-id'] || 
                     req.query.companyId || 
                     req.body.companyId ||
                     req.params.companyId;

    if (!companyId) {
      return res.status(400).json({ 
        error: 'Company context required',
        message: 'Please provide companyId in headers, query, or body, or ensure user has companyId'
      });
    }

    // Validate companyId format
    if (!require('mongoose').Types.ObjectId.isValid(companyId)) {
      return res.status(400).json({ 
        error: 'Invalid company ID format',
        message: 'Company ID must be a valid MongoDB ObjectId'
      });
    }

    // Find and validate company exists and is active
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ 
        error: 'Company not found',
        message: 'The specified company does not exist'
      });
    }

    if (company.status !== 'active' && company.status !== 'trial') {
      return res.status(403).json({ 
        error: 'Company inactive',
        message: 'This company account is not active'
      });
    }

    // Check if trial company has expired
    if (company.status === 'trial') {
      const now = new Date();
      if (company.trialEndDate && now > company.trialEndDate) {
        return res.status(403).json({ 
          error: 'Trial expired',
          message: 'Your trial period has expired. Please contact your administrator to activate your account.',
          trialEndDate: company.trialEndDate,
          daysExpired: Math.floor((now - company.trialEndDate) / (1000 * 60 * 60 * 24))
        });
      }
    }

    // Set company context for the request
    req.company = company;
    req.companyId = companyId;

    // Add company context to response headers for debugging
    res.set('X-Company-ID', companyId);
    res.set('X-Company-Name', company.name);

    next();
  } catch (error) {
    console.error('Company context validation error:', error);
    return res.status(500).json({ 
      error: 'Company context validation failed',
      message: 'Internal server error during company validation'
    });
  }
};

/**
 * Middleware to ensure user belongs to the specified company
 * This should be used after authentication middleware
 */
const validateUserCompanyAccess = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required',
        message: 'User must be authenticated'
      });
    }

    if (!req.companyId) {
      return res.status(400).json({ 
        error: 'Company context required',
        message: 'Company context must be set before user validation'
      });
    }

    // Check if user belongs to the specified company
    if (req.user.companyId && req.user.companyId.toString() !== req.companyId) {
      return res.status(403).json({ 
        error: 'Access denied',
        message: 'User does not have access to this company'
      });
    }

    next();
  } catch (error) {
    console.error('User company access validation error:', error);
    return res.status(500).json({ 
      error: 'User company access validation failed',
      message: 'Internal server error during user validation'
    });
  }
};

/**
 * Middleware to check if a specific feature is enabled for the company
 * Usage: requireFeature('analytics')
 */
const requireFeature = (featureName) => {
  return (req, res, next) => {
    if (!req.company) {
      return res.status(400).json({ 
        error: 'Company context required',
        message: 'Company context must be set before feature validation'
      });
    }

    if (!req.company.isFeatureEnabled(featureName)) {
      return res.status(403).json({ 
        error: 'Feature not available',
        message: `The ${featureName} feature is not enabled for this company`
      });
    }

    next();
  };
};

/**
 * Middleware to check company usage limits
 * Usage: checkUsageLimit('maxEmployees', currentEmployeeCount)
 */
const checkUsageLimit = (limitType, getCurrentValue) => {
  return async (req, res, next) => {
    try {
      if (!req.company) {
        return res.status(400).json({ 
          error: 'Company context required',
          message: 'Company context must be set before usage validation'
        });
      }

      const currentValue = typeof getCurrentValue === 'function' 
        ? await getCurrentValue(req) 
        : getCurrentValue;

      if (!req.company.isWithinLimits(limitType, currentValue)) {
        return res.status(403).json({ 
          error: 'Usage limit exceeded',
          message: `Company has exceeded the ${limitType} limit`
        });
      }

      next();
    } catch (error) {
      console.error('Usage limit check error:', error);
      return res.status(500).json({ 
        error: 'Usage limit validation failed',
        message: 'Internal server error during usage validation'
      });
    }
  };
};

/**
 * Helper function to add company filter to queries
 * Usage: addCompanyFilter(query, req.companyId)
 */
const addCompanyFilter = (query, companyId) => {
  if (!companyId) {
    throw new Error('Company ID is required for data filtering');
  }
  
  return { ...query, companyId };
};

/**
 * Helper function to get company-specific file path
 * Usage: getCompanyFilePath(req.companyId, fileName)
 */
const getCompanyFilePath = (companyId, fileName) => {
  if (!companyId) {
    throw new Error('Company ID is required for file path generation');
  }
  
  return `uploads/companies/${companyId}/${fileName}`;
};

module.exports = {
  validateCompanyContext,
  validateUserCompanyAccess,
  requireFeature,
  checkUsageLimit,
  addCompanyFilter,
  getCompanyFilePath
}; 