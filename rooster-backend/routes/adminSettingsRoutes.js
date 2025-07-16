const express = require('express');
const router = express.Router();
const adminSettingsController = require('../controllers/admin-settings-controller');
const { authenticateToken } = require('../middleware/auth');
const companyUpload = require('../gcsCompanyUpload');

// Admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

// GET /api/admin/settings - Get admin settings
router.get('/', authenticateToken, adminOnly, adminSettingsController.getAdminSettings);

// PUT /api/admin/settings - Update admin settings
router.put('/', authenticateToken, adminOnly, adminSettingsController.updateAdminSettings);

// Payroll cycle settings
router.get('/payroll-cycle', authenticateToken, adminOnly, adminSettingsController.getPayrollCycleSettings);
router.put('/payroll-cycle', authenticateToken, adminOnly, adminSettingsController.updatePayrollCycleSettings);

// Tax settings
router.get('/tax', authenticateToken, adminOnly, adminSettingsController.getTaxSettings);
router.put('/tax', authenticateToken, adminOnly, adminSettingsController.updateTaxSettings);

// Company information settings
router.get('/company', authenticateToken, adminOnly, adminSettingsController.getCompanyInfo);
router.put('/company', authenticateToken, adminOnly, adminSettingsController.updateCompanyInfo);
router.post('/company/logo', authenticateToken, adminOnly, companyUpload.single('logo'), adminSettingsController.uploadCompanyLogo);

// POST /api/admin/settings/reset - Reset settings to defaults
router.post('/reset', authenticateToken, adminOnly, adminSettingsController.resetAdminSettings);

module.exports = router; 