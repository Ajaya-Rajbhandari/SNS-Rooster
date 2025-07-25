const express = require('express');
const router = express.Router();
const Company = require('../models/Company');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');

// Get all companies (super admin only)
router.get('/', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const companies = await Company.find().select('-integrations.email.apiKey');
    res.json({ companies });
  } catch (error) {
    console.error('Error fetching companies:', error);
    res.status(500).json({ error: 'Failed to fetch companies' });
  }
});

// Get available companies for login selection
router.get('/available', async (req, res) => {
  try {
    // Get all companies except cancelled ones for login
    const companies = await Company.find({ 
      status: { $ne: 'cancelled' } 
    }).select('name domain subdomain adminEmail subscriptionPlan status');
    
    res.json({
      companies: companies.map(company => ({
        id: company._id,
        name: company.name,
        domain: company.domain,
        subdomain: company.subdomain,
        adminEmail: company.adminEmail,
        subscriptionPlan: company.subscriptionPlan,
        status: company.status
      }))
    });
  } catch (error) {
    console.error('Error fetching available companies:', error);
    res.status(500).json({ error: 'Failed to fetch available companies' });
  }
});

// Get company features (public endpoint for login) - MUST BE BEFORE /:companyId
router.get('/features/public/:companyId', async (req, res) => {
  try {
    const { companyId } = req.params;
    
    if (!companyId) {
      return res.status(400).json({ error: 'Company ID is required' });
    }

    const company = await Company.findById(companyId).populate('subscriptionPlan');
    
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    // Handle companies without subscription plans - provide default features
    const subscriptionPlan = company.subscriptionPlan;
    const planFeatures = subscriptionPlan?.features || {};
    
    // Default features for companies without plans
    const defaultFeatures = {
      attendance: true,
      payroll: true,
      leaveManagement: true,
      analytics: false,
      documentManagement: true,
      notifications: true,
      customBranding: false,
      apiAccess: false,
      multiLocation: false,
      advancedReporting: false,
      timeTracking: true,
      expenseManagement: false,
      performanceReviews: false,
      trainingManagement: false,
      locationBasedAttendance: false,
      // Location management features
      locationManagement: false,
      locationSettings: false,
      locationNotifications: false,
      locationGeofencing: false,
      locationCapacity: false,
    };

    // Default limits for companies without plans
    const defaultLimits = {
      maxEmployees: 10,
      maxStorageGB: 5,
      maxApiCallsPerDay: 1000,
      maxDepartments: 3,
      dataRetention: 365,
    };

    const response = {
      features: {
        // Feature flags (boolean values only) - use plan features or defaults
        attendance: defaultFeatures.attendance,
        payroll: defaultFeatures.payroll,
        leaveManagement: defaultFeatures.leaveManagement,
        analytics: planFeatures.analytics || defaultFeatures.analytics,
        documentManagement: defaultFeatures.documentManagement,
        notifications: defaultFeatures.notifications,
        customBranding: planFeatures.customBranding || defaultFeatures.customBranding,
        apiAccess: planFeatures.apiAccess || defaultFeatures.apiAccess,
        multiLocation: planFeatures.multiLocationSupport || defaultFeatures.multiLocation,
        advancedReporting: planFeatures.advancedReporting || defaultFeatures.advancedReporting,
        timeTracking: defaultFeatures.timeTracking,
        expenseManagement: planFeatures.expenseManagement || defaultFeatures.expenseManagement,
        performanceReviews: planFeatures.performanceReviews || defaultFeatures.performanceReviews,
        trainingManagement: planFeatures.trainingManagement || defaultFeatures.trainingManagement,
        locationBasedAttendance: planFeatures.locationBasedAttendance || defaultFeatures.locationBasedAttendance,
        // Location management features - enabled for Professional and Enterprise plans
        locationManagement: planFeatures.locationManagement !== undefined ? planFeatures.locationManagement : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationSettings: planFeatures.locationSettings !== undefined ? planFeatures.locationSettings : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationNotifications: planFeatures.locationNotifications !== undefined ? planFeatures.locationNotifications : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationGeofencing: planFeatures.locationGeofencing !== undefined ? planFeatures.locationGeofencing : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationCapacity: planFeatures.locationCapacity !== undefined ? planFeatures.locationCapacity : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
      },
      limits: {
        maxEmployees: planFeatures.maxEmployees || defaultLimits.maxEmployees,
        maxStorageGB: planFeatures.maxStorageGB || defaultLimits.maxStorageGB,
        maxApiCallsPerDay: planFeatures.maxApiCallsPerDay || defaultLimits.maxApiCallsPerDay,
        maxDepartments: planFeatures.maxDepartments || defaultLimits.maxDepartments,
        dataRetention: planFeatures.dataRetention || defaultLimits.dataRetention,
      },
      subscription: {
        planName: subscriptionPlan?.name || 'Basic',
        planType: subscriptionPlan?.type || 'basic',
        status: company.status
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching company features:', error);
    res.status(500).json({ error: 'Failed to fetch company features' });
  }
});

// Get company features (for frontend feature checking) - MUST BE BEFORE /:companyId
router.get('/features', authenticateToken, validateCompanyContext, async (req, res) => {
  try {
    const company = await Company.findById(req.companyId).populate('subscriptionPlan');
    
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    // Get current usage and update stored usage
    const User = require('../models/User');
    const employeeCount = await User.countDocuments({ 
      companyId: req.companyId,
      role: { $ne: 'super_admin' }
    });

    // Update the company's stored usage data
    if (!company.usage) {
      company.usage = {};
    }
    company.usage.currentEmployeeCount = employeeCount;
    company.usage.lastUsageUpdate = new Date();
    await company.save();

    // Calculate usage percentages
    const usage = {
      currentEmployeeCount: employeeCount,
      currentStorageGB: company.usage.currentStorageGB || 0,
      currentApiCallsToday: company.usage.currentApiCallsToday || 0,
    };

    // Handle companies without subscription plans - provide default features
    const subscriptionPlan = company.subscriptionPlan;
    const planFeatures = subscriptionPlan?.features || {};
    
    // Default features for companies without plans
    const defaultFeatures = {
      attendance: true,
      payroll: true,
      leaveManagement: true,
      analytics: false,
      documentManagement: true,
      notifications: true,
      customBranding: false,
      apiAccess: false,
      multiLocation: false,
      advancedReporting: false,
      timeTracking: true,
      expenseManagement: false,
      performanceReviews: false,
      trainingManagement: false,
      locationBasedAttendance: false,
      // Location management features
      locationManagement: false,
      locationSettings: false,
      locationNotifications: false,
      locationGeofencing: false,
      locationCapacity: false,
    };

    // Default limits for companies without plans
    const defaultLimits = {
      maxEmployees: 10,
      maxStorageGB: 5,
      maxApiCallsPerDay: 1000,
      maxDepartments: 3,
      dataRetention: 365,
    };

    const response = {
      features: {
        // Feature flags (boolean values only) - use plan features or defaults
        attendance: defaultFeatures.attendance,
        payroll: defaultFeatures.payroll,
        leaveManagement: defaultFeatures.leaveManagement,
        analytics: planFeatures.analytics || defaultFeatures.analytics,
        documentManagement: defaultFeatures.documentManagement,
        notifications: defaultFeatures.notifications,
        customBranding: planFeatures.customBranding || defaultFeatures.customBranding,
        apiAccess: planFeatures.apiAccess || defaultFeatures.apiAccess,
        multiLocation: planFeatures.multiLocationSupport || defaultFeatures.multiLocation,
        advancedReporting: planFeatures.advancedReporting || defaultFeatures.advancedReporting,
        timeTracking: defaultFeatures.timeTracking,
        expenseManagement: planFeatures.expenseManagement || defaultFeatures.expenseManagement,
        performanceReviews: planFeatures.performanceReviews || defaultFeatures.performanceReviews,
        trainingManagement: planFeatures.trainingManagement || defaultFeatures.trainingManagement,
        locationBasedAttendance: planFeatures.locationBasedAttendance || defaultFeatures.locationBasedAttendance,
        // Location management features - enabled for Professional and Enterprise plans
        locationManagement: planFeatures.locationManagement !== undefined ? planFeatures.locationManagement : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationSettings: planFeatures.locationSettings !== undefined ? planFeatures.locationSettings : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationNotifications: planFeatures.locationNotifications !== undefined ? planFeatures.locationNotifications : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationGeofencing: planFeatures.locationGeofencing !== undefined ? planFeatures.locationGeofencing : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
        locationCapacity: planFeatures.locationCapacity !== undefined ? planFeatures.locationCapacity : (subscriptionPlan?.name?.toLowerCase() !== 'basic'),
      },
      limits: {
        maxEmployees: planFeatures.maxEmployees || defaultLimits.maxEmployees,
        maxStorageGB: planFeatures.maxStorageGB || defaultLimits.maxStorageGB,
        maxApiCallsPerDay: planFeatures.maxApiCallsPerDay || defaultLimits.maxApiCallsPerDay,
        maxDepartments: planFeatures.maxDepartments || defaultLimits.maxDepartments,
        dataRetention: planFeatures.dataRetention || defaultLimits.dataRetention,
      },
      usage: usage,
      subscriptionPlan: {
        name: subscriptionPlan?.name || 'Basic',
        price: subscriptionPlan?.price || { monthly: 29, yearly: 290 },
        features: subscriptionPlan?.features || defaultFeatures
      },
      company: {
        name: company.name,
        domain: company.domain,
        subdomain: company.subdomain,
        status: company.status
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching company features:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get company by ID
router.get('/:companyId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const company = await Company.findById(req.companyId).select('-integrations.email.apiKey');
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }
    res.json({ company });
  } catch (error) {
    console.error('Error fetching company:', error);
    res.status(500).json({ error: 'Failed to fetch company' });
  }
});

// Create new company (super admin only)
router.post('/', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const {
      name,
      domain,
      subdomain,
      adminEmail,
      contactPhone,
      address,
      subscriptionPlan = 'basic',
      features = {},
      limits = {}
    } = req.body;

    // Validate required fields
    if (!name || !domain || !subdomain || !adminEmail) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        message: 'Name, domain, subdomain, and adminEmail are required'
      });
    }

    // Check if domain or subdomain already exists
    const existingCompany = await Company.findOne({
      $or: [{ domain: domain.toLowerCase() }, { subdomain: subdomain.toLowerCase() }]
    });

    if (existingCompany) {
      return res.status(400).json({ 
        error: 'Domain or subdomain already exists',
        message: 'Please choose a different domain or subdomain'
      });
    }

    // Create company with default settings
    const company = new Company({
      name,
      domain: domain.toLowerCase(),
      subdomain: subdomain.toLowerCase(),
      adminEmail: adminEmail.toLowerCase(),
      contactPhone,
      address,
      subscriptionPlan,
      features: {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: subscriptionPlan !== 'basic',
        documentManagement: true,
        notifications: true,
        customBranding: subscriptionPlan !== 'basic',
        apiAccess: subscriptionPlan === 'enterprise',
        multiLocation: subscriptionPlan === 'enterprise',
        advancedReporting: subscriptionPlan === 'enterprise',
        timeTracking: true,
        expenseManagement: subscriptionPlan !== 'basic',
        performanceReviews: subscriptionPlan === 'enterprise',
        trainingManagement: subscriptionPlan === 'enterprise',
        // Location management features
        locationManagement: subscriptionPlan !== 'basic',
        locationSettings: subscriptionPlan !== 'basic',
        locationNotifications: subscriptionPlan !== 'basic',
        locationGeofencing: subscriptionPlan !== 'basic',
        locationCapacity: subscriptionPlan !== 'basic',
        locationBasedAttendance: subscriptionPlan !== 'basic',
        ...features
      },
      limits: {
        maxEmployees: subscriptionPlan === 'basic' ? 25 : subscriptionPlan === 'professional' ? 100 : 500,
        maxStorageGB: subscriptionPlan === 'basic' ? 5 : subscriptionPlan === 'professional' ? 20 : 100,
        retentionDays: 365,
        maxApiCallsPerDay: subscriptionPlan === 'basic' ? 1000 : subscriptionPlan === 'professional' ? 5000 : 10000,
        maxLocations: subscriptionPlan === 'basic' ? 1 : subscriptionPlan === 'professional' ? 3 : 10,
        ...limits
      },
      status: 'trial', // Set to trial for new companies
      trialSubscriptionPlan: subscriptionPlan, // Track which plan the trial is for
      trialPlanName: `${subscriptionPlan.charAt(0).toUpperCase() + subscriptionPlan.slice(1)} Trial`, // e.g., "Basic Trial", "Professional Trial"
      trialStartDate: new Date(),
      trialEndDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days trial
      trialDurationDays: 7
    });

    await company.save();
    res.status(201).json({ 
      company,
      message: 'Company created successfully'
    });
  } catch (error) {
    console.error('Error creating company:', error);
    res.status(500).json({ error: 'Failed to create company' });
  }
});

// Update company
router.put('/:companyId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const {
      name,
      contactPhone,
      address,
      branding,
      settings,
      integrations
    } = req.body;

    const updateData = {};
    if (name) updateData.name = name;
    if (contactPhone) updateData.contactPhone = contactPhone;
    if (address) updateData.address = address;
    if (branding) updateData.branding = { ...req.company.branding, ...branding };
    if (settings) updateData.settings = { ...req.company.settings, ...settings };
    if (integrations) updateData.integrations = { ...req.company.integrations, ...integrations };

    const company = await Company.findByIdAndUpdate(
      req.companyId,
      updateData,
      { new: true, runValidators: true }
    ).select('-integrations.email.apiKey');

    res.json({ 
      company,
      message: 'Company updated successfully'
    });
  } catch (error) {
    console.error('Error updating company:', error);
    res.status(500).json({ error: 'Failed to update company' });
  }
});

// Update company features (super admin only)
router.patch('/:companyId/features', authenticateToken, authorizeRoles('admin'), validateCompanyContext, async (req, res) => {
  try {
    const { features } = req.body;
    
    if (!features || typeof features !== 'object') {
      return res.status(400).json({ 
        error: 'Invalid features data',
        message: 'Features must be an object'
      });
    }

    const company = await Company.findByIdAndUpdate(
      req.companyId,
      { $set: { features: { ...req.company.features, ...features } } },
      { new: true, runValidators: true }
    ).select('-integrations.email.apiKey');

    res.json({ 
      company,
      message: 'Company features updated successfully'
    });
  } catch (error) {
    console.error('Error updating company features:', error);
    res.status(500).json({ error: 'Failed to update company features' });
  }
});

// Update company limits (super admin only)
router.patch('/:companyId/limits', authenticateToken, authorizeRoles('admin'), validateCompanyContext, async (req, res) => {
  try {
    const { limits } = req.body;
    
    if (!limits || typeof limits !== 'object') {
      return res.status(400).json({ 
        error: 'Invalid limits data',
        message: 'Limits must be an object'
      });
    }

    const company = await Company.findByIdAndUpdate(
      req.companyId,
      { $set: { limits: { ...req.company.limits, ...limits } } },
      { new: true, runValidators: true }
    ).select('-integrations.email.apiKey');

    res.json({ 
      company,
      message: 'Company limits updated successfully'
    });
  } catch (error) {
    console.error('Error updating company limits:', error);
    res.status(500).json({ error: 'Failed to update company limits' });
  }
});

// Update company status (super admin only)
router.patch('/:companyId/status', authenticateToken, authorizeRoles('admin'), validateCompanyContext, async (req, res) => {
  try {
    const { status } = req.body;
    
    const validStatuses = ['active', 'suspended', 'trial', 'expired', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status',
        message: `Status must be one of: ${validStatuses.join(', ')}`
      });
    }

    const company = await Company.findByIdAndUpdate(
      req.companyId,
      { status },
      { new: true, runValidators: true }
    ).select('-integrations.email.apiKey');

    res.json({ 
      company,
      message: 'Company status updated successfully'
    });
  } catch (error) {
    console.error('Error updating company status:', error);
    res.status(500).json({ error: 'Failed to update company status' });
  }
});

// Get company usage statistics
router.get('/:companyId/usage', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const User = require('../models/User');
    const Employee = require('../models/Employee');
    const Attendance = require('../models/Attendance');

    const [userCount, employeeCount, attendanceCount] = await Promise.all([
      User.countDocuments({ companyId: req.companyId }),
      Employee.countDocuments({ companyId: req.companyId }),
      Attendance.countDocuments({ companyId: req.companyId })
    ]);

    const usage = {
      employees: {
        current: userCount,
        limit: req.company.limits.maxEmployees,
        percentage: Math.round((userCount / req.company.limits.maxEmployees) * 100)
      },
      storage: {
        current: 0, // TODO: Implement storage calculation
        limit: req.company.limits.maxStorageGB,
        percentage: 0
      }
    };

    res.json({ usage });
  } catch (error) {
    console.error('Error fetching company usage:', error);
    res.status(500).json({ error: 'Failed to fetch company usage' });
  }
});

// Delete company (super admin only)
router.delete('/:companyId', authenticateToken, authorizeRoles('admin'), validateCompanyContext, async (req, res) => {
  try {
    // Check if company has any data
    const User = require('../models/User');
    const userCount = await User.countDocuments({ companyId: req.companyId });
    
    if (userCount > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete company with existing data',
        message: 'Please remove all users and data before deleting the company'
      });
    }

    await Company.findByIdAndDelete(req.companyId);
    res.json({ message: 'Company deleted successfully' });
  } catch (error) {
    console.error('Error deleting company:', error);
    res.status(500).json({ error: 'Failed to delete company' });
  }
});

module.exports = router; 