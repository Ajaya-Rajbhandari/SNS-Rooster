const express = require('express');
const router = express.Router();
const adminSettingsController = require('../controllers/admin-settings-controller');
const auth = require('../middleware/auth');

// Admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

// GET /api/admin/settings - Get admin settings
router.get('/', auth, adminOnly, adminSettingsController.getAdminSettings);

// PUT /api/admin/settings - Update admin settings
router.put('/', auth, adminOnly, adminSettingsController.updateAdminSettings);

// Payroll cycle settings
router.get('/payroll-cycle', auth, adminOnly, adminSettingsController.getPayrollCycleSettings);
router.put('/payroll-cycle', auth, adminOnly, adminSettingsController.updatePayrollCycleSettings);

// POST /api/admin/settings/reset - Reset settings to defaults
router.post('/reset', auth, adminOnly, adminSettingsController.resetAdminSettings);

module.exports = router; 