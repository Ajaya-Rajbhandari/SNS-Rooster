const AdminSettings = require('../models/AdminSettings');
const User = require('../models/User');

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