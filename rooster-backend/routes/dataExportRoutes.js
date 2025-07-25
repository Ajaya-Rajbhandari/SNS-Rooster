const express = require('express');
const router = express.Router();
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const dataExportController = require('../controllers/dataExport-controller');
const { authenticateToken } = require('../middleware/auth');

// Apply company context middleware to all routes
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);

// ===== DATA EXPORT ENDPOINTS =====

// Export attendance data
router.get('/attendance', authenticateToken, dataExportController.exportAttendance);

// Export leave data
router.get('/leave', authenticateToken, dataExportController.exportLeave);

// Export employee data
router.get('/employees', authenticateToken, dataExportController.exportEmployees);

// Export payroll data
router.get('/payroll', authenticateToken, dataExportController.exportPayroll);

// Export analytics data
router.get('/analytics', authenticateToken, dataExportController.exportAnalytics);

// ===== EXPORT MANAGEMENT =====

// Get available export formats
router.get('/formats', authenticateToken, dataExportController.getExportFormats);

// Get export statistics
router.get('/stats', authenticateToken, dataExportController.getExportStats);

// Clean up old export files
router.delete('/cleanup', authenticateToken, dataExportController.cleanupExports);

module.exports = router; 