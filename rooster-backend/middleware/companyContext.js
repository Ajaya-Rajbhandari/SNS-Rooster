const Company = require('../models/Company');

/**
 * Middleware to resolve company context from request
 * Supports multiple ways to identify company:
 * 1. Domain-based resolution (for web apps)
 * 2. Subdomain-based resolution (for mobile apps)
 * 3. Company ID in headers or query params
 */
const resolveCompanyContext = async (req, res, next) => {
  try {
    let company = null;
    
    // Method 1: Try to get company from domain
    const host = req.get('host') || req.headers.host;
    if (host) {
      // Extract domain from host (e.g., "company1.rooster.com" -> "company1")
      const domain = host.split('.')[0];
      if (domain && domain !== 'www' && domain !== 'api') {
        company = await Company.findByDomain(domain);
      }
    }
    
    // Method 2: Try to get company from subdomain
    if (!company && host) {
      const subdomain = host.split('.')[0];
      if (subdomain && subdomain !== 'www' && subdomain !== 'api') {
        company = await Company.findBySubdomain(subdomain);
      }
    }
    
    // Method 3: Try to get company from headers
    if (!company) {
      const companyId = req.headers['x-company-id'] || req.headers['company-id'];
      if (companyId) {
        company = await Company.findById(companyId);
      }
    }
    
    // Method 4: Try to get company from query params
    if (!company) {
      const companyId = req.query.companyId;
      if (companyId) {
        company = await Company.findById(companyId);
      }
    }
    
    // Method 5: Try to get company from JWT token (if user is authenticated)
    if (!company && req.user && req.user.companyId) {
      company = await Company.findById(req.user.companyId);
    }
    
    // If no company found, use default company for backward compatibility
    if (!company) {
      company = await Company.findByDomain('default');
    }
    
    if (!company) {
      return res.status(404).json({
        error: 'Company not found',
        message: 'Unable to resolve company context'
      });
    }
    
    // Check if company is active
    if (!company.isActive()) {
      return res.status(403).json({
        error: 'Company inactive',
        message: 'This company account is not active'
      });
    }
    
    // Attach company context to request
    req.company = company;
    req.companyId = company._id;
    
    next();
  } catch (error) {
    console.error('Error resolving company context:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to resolve company context'
    });
  }
};

/**
 * Middleware to require company context
 * This middleware ensures that a valid company context is available
 */
const requireCompanyContext = (req, res, next) => {
  if (!req.company || !req.companyId) {
    return res.status(403).json({
      error: 'Company context required',
      message: 'Company context is required for this operation'
    });
  }
  next();
};

/**
 * Middleware to validate feature access
 * Checks if the requested feature is enabled for the company
 */
const validateFeatureAccess = (featureName) => {
  return (req, res, next) => {
    if (!req.company) {
      return res.status(403).json({
        error: 'Company context required',
        message: 'Company context is required for feature validation'
      });
    }
    
    if (!req.company.isFeatureEnabled(featureName)) {
      return res.status(403).json({
        error: 'Feature not available',
        message: `Feature '${featureName}' is not enabled for this company`
      });
    }
    
    next();
  };
};

/**
 * Middleware to check company limits
 * Validates if the company has not exceeded its usage limits
 */
const checkCompanyLimits = (limitType) => {
  return async (req, res, next) => {
    try {
      if (!req.company) {
        return res.status(403).json({
          error: 'Company context required',
          message: 'Company context is required for limit validation'
        });
      }
      
      const limits = req.company.limits;
      
      switch (limitType) {
        case 'employees':
          // Check employee count limit
          const User = require('../models/User');
          const employeeCount = await User.countDocuments({ 
            companyId: req.companyId,
            role: 'employee'
          });
          
          if (employeeCount >= limits.maxEmployees) {
            return res.status(403).json({
              error: 'Employee limit exceeded',
              message: `Maximum number of employees (${limits.maxEmployees}) reached`
            });
          }
          break;
          
        case 'storage':
          // Check storage usage limit
          // This would need to be implemented based on your file storage system
          break;
          
        case 'api_calls':
          // Check API call limit
          // This would need to be implemented with a rate limiting system
          break;
          
        default:
          console.warn(`Unknown limit type: ${limitType}`);
      }
      
      next();
    } catch (error) {
      console.error('Error checking company limits:', error);
      return res.status(500).json({
        error: 'Internal server error',
        message: 'Failed to validate company limits'
      });
    }
  };
};

/**
 * Helper function to add company filter to queries
 */
const addCompanyFilter = (query, companyId) => {
  if (!companyId) {
    throw new Error('Company ID is required for query filtering');
  }
  
  return query.where('companyId', companyId);
};

/**
 * Helper function to validate company ownership
 * Ensures that a resource belongs to the current company
 */
const validateCompanyOwnership = async (model, resourceId, companyId) => {
  if (!resourceId || !companyId) {
    throw new Error('Resource ID and Company ID are required for ownership validation');
  }
  
  const resource = await model.findOne({ _id: resourceId, companyId });
  if (!resource) {
    throw new Error('Resource not found or does not belong to this company');
  }
  
  return resource;
};

module.exports = {
  resolveCompanyContext,
  requireCompanyContext,
  validateFeatureAccess,
  checkCompanyLimits,
  addCompanyFilter,
  validateCompanyOwnership
}; 