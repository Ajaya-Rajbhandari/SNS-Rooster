const AdminSettings = require('../models/AdminSettings');
const path = require('path');
const fs = require('fs');
const cloudStorageService = require('../services/cloud-storage-service');

// Get admin settings
exports.getAdminSettings = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings(req.companyId);
    res.json({ settings });
  } catch (error) {
    console.error('Get admin settings error:', error);
    res.status(500).json({ message: 'Failed to fetch admin settings' });
  }
};

// Update admin settings
exports.updateAdminSettings = async (req, res) => {
  try {
    const updates = req.body;
    const settings = await AdminSettings.updateSettings(updates, req.companyId);
    
    // If profile feature settings were changed, recalculate all user profile completeness
    const profileFeatureChanged = 
      updates.hasOwnProperty('educationSectionEnabled') || 
      updates.hasOwnProperty('certificatesSectionEnabled') ||
      updates.hasOwnProperty('requiredProfileFields');
    
    if (profileFeatureChanged) {
      // Update all users' profile completion status for this company
      const users = await User.find({ role: 'employee', companyId: req.companyId });
      for (const user of users) {
        await user.recalculateProfileComplete();
        await user.save();
      }
      console.log(`Updated profile completion status for ${users.length} users in company ${req.companyId}`);
    }
    
    res.json({ 
      message: 'Admin settings updated successfully',
      settings,
      updatedUsers: profileFeatureChanged ? true : false
    });
  } catch (error) {
    console.error('Update admin settings error:', error);
    res.status(500).json({ message: 'Failed to update admin settings' });
  }
};

// Reset admin settings to defaults
exports.resetAdminSettings = async (req, res) => {
  try {
    await AdminSettings.deleteMany({ companyId: req.companyId });
    const settings = await AdminSettings.getSettings(req.companyId); // This will create default settings
    
    // Recalculate all user profile completeness with default settings for this company
    const users = await User.find({ role: 'employee', companyId: req.companyId });
    for (const user of users) {
      await user.recalculateProfileComplete();
      await user.save();
    }
    
    res.json({ 
      message: 'Admin settings reset to defaults',
      settings,
      updatedUsers: users.length
    });
  } catch (error) {
    console.error('Reset admin settings error:', error);
    res.status(500).json({ message: 'Failed to reset admin settings' });
  }
};

// === Payroll Cycle Settings ===
// GET /api/admin/settings/payroll-cycle
exports.getPayrollCycleSettings = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings(req.companyId);
    res.json(settings.payrollCycle || {});
  } catch (error) {
    console.error('Get payroll cycle settings error:', error);
    res.status(500).json({ message: 'Failed to fetch payroll cycle settings' });
  }
};

// PUT /api/admin/settings/payroll-cycle
exports.updatePayrollCycleSettings = async (req, res) => {
  try {
    const cycleUpdates = req.body; // assume validated
    const settings = await AdminSettings.updateSettings({ payrollCycle: cycleUpdates }, req.companyId);
    res.json({ message: 'Payroll cycle settings updated', payrollCycle: settings.payrollCycle });
  } catch (error) {
    console.error('Update payroll cycle settings error:', error);
    res.status(500).json({ message: 'Failed to update payroll cycle settings' });
  }
};

// === Tax Settings ===
// GET /api/admin/settings/tax
exports.getTaxSettings = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings(req.companyId);
    res.json(settings.taxSettings || {});
  } catch (error) {
    console.error('Get tax settings error:', error);
    res.status(500).json({ message: 'Failed to fetch tax settings' });
  }
};

// PUT /api/admin/settings/tax
exports.updateTaxSettings = async (req, res) => {
  try {
    const taxUpdates = req.body; // assume validated
    
    // Validate tax brackets if provided
    if (taxUpdates.incomeTaxBrackets) {
      for (let bracket of taxUpdates.incomeTaxBrackets) {
        if (bracket.rate < 0 || bracket.rate > 100) {
          return res.status(400).json({ message: 'Tax rate must be between 0 and 100%' });
        }
        if (bracket.minAmount < 0) {
          return res.status(400).json({ message: 'Minimum amount cannot be negative' });
        }
        if (bracket.maxAmount !== null && bracket.maxAmount <= bracket.minAmount) {
          return res.status(400).json({ message: 'Maximum amount must be greater than minimum amount' });
        }
      }
    }

    // Validate flat tax rates if provided
    if (taxUpdates.flatTaxRates) {
      for (let flatRate of taxUpdates.flatTaxRates) {
        if (!flatRate.name || flatRate.name.trim() === '') {
          return res.status(400).json({ message: 'Tax rate name is required' });
        }
        if (flatRate.rate < 0 || flatRate.rate > 100) {
          return res.status(400).json({ message: 'Tax rate must be between 0 and 100%' });
        }
      }
    }

    const settings = await AdminSettings.updateSettings({ taxSettings: taxUpdates }, req.companyId);
    res.json({ message: 'Tax settings updated', taxSettings: settings.taxSettings });
  } catch (error) {
    console.error('Update tax settings error:', error);
    res.status(500).json({ message: 'Failed to update tax settings' });
  }
};

// === Company Information Settings ===
// GET /api/admin/settings/company
exports.getCompanyInfo = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings(req.companyId);
    
    // Get company data with subscription and usage info
    const Company = require('../models/Company');
    const User = require('../models/User');
    
    const company = await Company.findById(req.companyId).populate('subscriptionPlan');
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }

    // Get current employee count
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

    // Build comprehensive response
    const response = {
      // Basic company info from AdminSettings
      ...settings.companyInfo,
      
      // Company data from Company model
      companyId: company._id,
      name: company.name,
      domain: company.domain,
      subdomain: company.subdomain,
      status: company.status,
      
      // Subscription information
      subscriptionPlan: {
        name: company.subscriptionPlan?.name || 'Basic',
        price: company.subscriptionPlan?.price || { monthly: 29, yearly: 290 },
        features: company.subscriptionPlan?.features || {}
      },
      
      // Usage statistics
      usage: {
        currentEmployeeCount: employeeCount,
        currentStorageGB: company.usage.currentStorageGB || 0,
        currentApiCallsToday: company.usage.currentApiCallsToday || 0,
      },
      
      // Limits
      limits: {
        maxEmployees: company.limits?.maxEmployees || 10,
        maxStorageGB: company.limits?.maxStorageGB || 5,
        maxApiCallsPerDay: company.limits?.maxApiCallsPerDay || 1000,
        maxDepartments: company.limits?.maxDepartments || 3,
        dataRetention: company.limits?.dataRetention || 365,
      },
      
      // Features
      features: {
        attendance: company.features?.attendance || true,
        payroll: company.features?.payroll || true,
        leaveManagement: company.features?.leaveManagement || true,
        analytics: company.features?.analytics || false,
        documentManagement: company.features?.documentManagement || true,
        notifications: company.features?.notifications || true,
        customBranding: company.features?.customBranding || false,
        apiAccess: company.features?.apiAccess || false,
        multiLocation: company.features?.multiLocation || false,
        advancedReporting: company.features?.advancedReporting || false,
        timeTracking: company.features?.timeTracking || true,
        expenseManagement: company.features?.expenseManagement || false,
        performanceReviews: company.features?.performanceReviews || false,
        trainingManagement: company.features?.trainingManagement || false,
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Get company info error:', error);
    res.status(500).json({ message: 'Failed to fetch company information' });
  }
};

// PUT /api/admin/settings/company
exports.updateCompanyInfo = async (req, res) => {
  try {
    const companyUpdates = req.body;
    
    // Validate required fields
    if (!companyUpdates.name || companyUpdates.name.trim() === '') {
      return res.status(400).json({ message: 'Company name is required' });
    }

    // Validate email format if provided
    if (companyUpdates.email && companyUpdates.email.trim() !== '') {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(companyUpdates.email)) {
        return res.status(400).json({ message: 'Invalid email format' });
      }
    }

    // Validate website format if provided
    if (companyUpdates.website && companyUpdates.website.trim() !== '') {
      try {
        new URL(companyUpdates.website.startsWith('http') ? companyUpdates.website : `https://${companyUpdates.website}`);
      } catch {
        return res.status(400).json({ message: 'Invalid website URL format' });
      }
    }

    // Validate established year if provided
    if (companyUpdates.establishedYear) {
      const currentYear = new Date().getFullYear();
      const year = parseInt(companyUpdates.establishedYear);
      if (isNaN(year) || year < 1800 || year > currentYear) {
        return res.status(400).json({ message: 'Invalid established year' });
      }
    }

    const settings = await AdminSettings.updateSettings({ companyInfo: companyUpdates }, req.companyId);
    res.json({ message: 'Company information updated', companyInfo: settings.companyInfo });
  } catch (error) {
    console.error('Update company info error:', error);
    res.status(500).json({ message: 'Failed to update company information' });
  }
};

// POST /api/admin/settings/company/logo
exports.uploadCompanyLogo = async (req, res) => {
  try {
    console.log('Upload company logo request received');
    console.log('Request file:', req.file);
    console.log('Request body:', req.body);
    console.log('Company ID:', req.companyId);
    console.log('Environment:', process.env.NODE_ENV);

    if (!req.file) {
      console.log('No file uploaded');
      return res.status(400).json({ message: 'No logo file uploaded' });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    console.log('Received file mimetype:', req.file.mimetype);
    console.log('Received file originalname:', req.file.originalname);
    console.log('Received file path:', req.file.path);
    console.log('Allowed types:', allowedTypes);
    
    // Check both mimetype and file extension
    const fileExtension = req.file.originalname.split('.').pop()?.toLowerCase();
    const isValidMimeType = allowedTypes.includes(req.file.mimetype);
    const isValidExtension = ['jpeg', 'jpg', 'png', 'gif'].includes(fileExtension);
    
    console.log('File extension:', fileExtension);
    console.log('Is valid MIME type:', isValidMimeType);
    console.log('Is valid extension:', isValidExtension);
    
    if (!isValidMimeType && !isValidExtension) {
      console.log('Invalid file type - MIME type and extension check failed');
      return res.status(400).json({ message: 'Invalid file type. Only JPEG, PNG and GIF are allowed' });
    }

    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (req.file.size > maxSize) {
      console.log('File too large:', req.file.size);
      return res.status(400).json({ message: 'File too large. Maximum size is 5MB' });
    }

    console.log('File validation passed');
    console.log('File path:', req.file.path);
    console.log('File filename:', req.file.filename);

    // Check if the file path is valid
    if (!req.file.path || !fs.existsSync(req.file.path)) {
      console.log('Invalid file path or file does not exist:', req.file.path);
      return res.status(400).json({ message: 'Invalid file path or file does not exist' });
    }

    let logoUrl;

    // Use cloud storage service (handles both development and production)
    console.log('Using cloud storage service for upload');
    logoUrl = await cloudStorageService.uploadFile(req.file);

    console.log('DEBUG: Logo URL:', logoUrl);

    // Update company info with new logo URL
    const settings = await AdminSettings.getSettings(req.companyId);
    console.log('Current settings:', settings);
    
    // Update with new logo URL
    const updatedSettings = await AdminSettings.updateSettings({
      companyInfo: { ...settings.companyInfo, logoUrl: logoUrl }
    }, req.companyId);

    console.log('Settings updated successfully');
    console.log('Updated logo URL:', logoUrl);

    res.json({
      message: 'Company logo uploaded successfully',
      logoUrl: logoUrl,
      companyInfo: updatedSettings.companyInfo
    });
  } catch (error) {
    console.error('Upload company logo error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ message: 'Failed to upload company logo', error: error.message });
  }
};

// GET /api/admin/settings/location
exports.getLocationSettings = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings(req.companyId);
    res.json({
      success: true,
      locationSettings: settings.locationSettings
    });
  } catch (error) {
    console.error('Get location settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get location settings'
    });
  }
};

// PUT /api/admin/settings/location
exports.updateLocationSettings = async (req, res) => {
  try {
    const { locationSettings } = req.body;
    
    // Validate location settings
    if (locationSettings.defaultGeofenceRadius) {
      const radius = parseInt(locationSettings.defaultGeofenceRadius);
      if (isNaN(radius) || radius < 10 || radius > 1000) {
        return res.status(400).json({
          success: false,
          message: 'Default geofence radius must be between 10 and 1000 meters'
        });
      }
    }

    if (locationSettings.defaultCapacity) {
      const capacity = parseInt(locationSettings.defaultCapacity);
      if (isNaN(capacity) || capacity < 1 || capacity > 1000) {
        return res.status(400).json({
          success: false,
          message: 'Default capacity must be between 1 and 1000 people'
        });
      }
    }

    if (locationSettings.defaultWorkingHours) {
      const { start, end } = locationSettings.defaultWorkingHours;
      const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
      
      if (start && !timeRegex.test(start)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid start time format. Use HH:MM format (e.g., 09:00)'
        });
      }
      
      if (end && !timeRegex.test(end)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid end time format. Use HH:MM format (e.g., 17:00)'
        });
      }
    }

    const settings = await AdminSettings.updateSettings({ locationSettings }, req.companyId);
    
    res.json({
      success: true,
      message: 'Location settings updated successfully',
      locationSettings: settings.locationSettings
    });
  } catch (error) {
    console.error('Update location settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update location settings'
    });
  }
};

 