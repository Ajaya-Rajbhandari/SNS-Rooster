const AdminSettings = require('../models/AdminSettings');
const User = require('../models/User');
const path = require('path');
const fs = require('fs');

// Get admin settings
exports.getAdminSettings = async (req, res) => {
  try {
    const settings = await AdminSettings.getSettings();
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
    const settings = await AdminSettings.updateSettings(updates);
    
    // If profile feature settings were changed, recalculate all user profile completeness
    const profileFeatureChanged = 
      updates.hasOwnProperty('educationSectionEnabled') || 
      updates.hasOwnProperty('certificatesSectionEnabled') ||
      updates.hasOwnProperty('requiredProfileFields');
    
    if (profileFeatureChanged) {
      // Update all users' profile completion status
      const users = await User.find({ role: 'employee' });
      for (const user of users) {
        await user.recalculateProfileComplete();
        await user.save();
      }
      console.log(`Updated profile completion status for ${users.length} users`);
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
    await AdminSettings.deleteMany({});
    const settings = await AdminSettings.getSettings(); // This will create default settings
    
    // Recalculate all user profile completeness with default settings
    const users = await User.find({ role: 'employee' });
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
    const settings = await AdminSettings.getSettings();
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
    const settings = await AdminSettings.updateSettings({ payrollCycle: cycleUpdates });
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
    const settings = await AdminSettings.getSettings();
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

    const settings = await AdminSettings.updateSettings({ taxSettings: taxUpdates });
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
    const settings = await AdminSettings.getSettings();
    res.json(settings.companyInfo || {});
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

    const settings = await AdminSettings.updateSettings({ companyInfo: companyUpdates });
    res.json({ message: 'Company information updated', companyInfo: settings.companyInfo });
  } catch (error) {
    console.error('Update company info error:', error);
    res.status(500).json({ message: 'Failed to update company information' });
  }
};

// POST /api/admin/settings/company/logo
exports.uploadCompanyLogo = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No logo file uploaded' });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    if (!allowedTypes.includes(req.file.mimetype)) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ message: 'Invalid file type. Only JPEG, PNG and GIF are allowed' });
    }

    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (req.file.size > maxSize) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ message: 'File too large. Maximum size is 5MB' });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const extension = path.extname(req.file.originalname);
    const filename = `company-logo-${timestamp}${extension}`;
    const logoPath = `uploads/company/${filename}`;
    const fullPath = path.join(__dirname, '..', logoPath);

    // Ensure upload directory exists
    const uploadDir = path.dirname(fullPath);
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    // Move file to permanent location
    fs.renameSync(req.file.path, fullPath);

    // Update company info with new logo URL
    const settings = await AdminSettings.getSettings();
    
    // Delete old logo file if exists
    if (settings.companyInfo?.logoUrl) {
      const oldLogoPath = path.join(__dirname, '..', settings.companyInfo.logoUrl);
      if (fs.existsSync(oldLogoPath)) {
        fs.unlinkSync(oldLogoPath);
      }
    }

    // Update with new logo URL
    const updatedSettings = await AdminSettings.updateSettings({
      companyInfo: { ...settings.companyInfo, logoUrl: logoPath }
    });

    res.json({
      message: 'Company logo uploaded successfully',
      logoUrl: logoPath,
      companyInfo: updatedSettings.companyInfo
    });
  } catch (error) {
    // Clean up uploaded file on error
    if (req.file?.path && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    console.error('Upload company logo error:', error);
    res.status(500).json({ message: 'Failed to upload company logo' });
  }
}; 