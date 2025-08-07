const express = require('express');
const router = express.Router();
const adminSettingsController = require('../controllers/admin-settings-controller');
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext } = require('../middleware/companyContext');
const upload = require('../middleware/upload'); // Use local upload middleware instead of GCS
const multer = require('multer'); // Added missing import for multer

// Admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

// Error handling middleware for multer
const handleUploadError = (error, req, res, next) => {
  console.error('Upload error:', error);
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'File too large. Maximum size is 5MB' });
    }
    return res.status(400).json({ message: 'File upload error: ' + error.message });
  } else if (error) {
    return res.status(400).json({ message: error.message });
  }
  next();
};

// GET /api/admin/settings - Get admin settings
router.get('/', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.getAdminSettings);

// PUT /api/admin/settings - Update admin settings
router.put('/', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.updateAdminSettings);

// Payroll cycle settings
router.get('/payroll-cycle', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.getPayrollCycleSettings);
router.put('/payroll-cycle', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.updatePayrollCycleSettings);

// Tax settings
router.get('/tax', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.getTaxSettings);
router.put('/tax', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.updateTaxSettings);

// Company information settings
router.get('/company', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.getCompanyInfo);
router.put('/company', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.updateCompanyInfo);
router.post('/company/logo', 
  authenticateToken, 
  adminOnly, 
  validateCompanyContext, 
  upload.single('logo'), 
  handleUploadError,
  adminSettingsController.uploadCompanyLogo
);

// Location settings
router.get('/location', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.getLocationSettings);
router.put('/location', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.updateLocationSettings);

// GET /api/admin/settings/company/logo/proxy
router.get('/company/logo/proxy', async (req, res) => {
  try {
    const { url } = req.query;
    
    if (!url) {
      return res.status(400).json({ message: 'Logo URL is required' });
    }

    console.log('DEBUG: Proxying logo from:', url);

    // Fetch the image from Firebase Storage
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'SNS-Rooster-Server/1.0',
      },
    });

    if (!response.ok) {
      console.log('DEBUG: Failed to fetch logo, status:', response.status);
      return res.status(response.status).json({ 
        message: 'Failed to fetch logo',
        status: response.status 
      });
    }

    // Get the image data
    const imageBuffer = await response.arrayBuffer();
    const contentType = response.headers.get('content-type') || 'image/png';

    console.log('DEBUG: Successfully proxied logo, size:', imageBuffer.byteLength, 'bytes');

    // Set appropriate headers
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
    // Remove conflicting CORS header - let main CORS middleware handle it
    // res.setHeader('Access-Control-Allow-Origin', '*');

    // Send the image
    res.send(Buffer.from(imageBuffer));

  } catch (error) {
    console.error('DEBUG: Error proxying logo:', error);
    res.status(500).json({ 
      message: 'Failed to proxy logo',
      error: error.message 
    });
  }
});

// POST /api/admin/settings/reset - Reset settings to defaults
router.post('/reset', authenticateToken, adminOnly, validateCompanyContext, adminSettingsController.resetAdminSettings);

module.exports = router; 