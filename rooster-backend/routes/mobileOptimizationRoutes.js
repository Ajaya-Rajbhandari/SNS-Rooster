const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const MobileOptimizationService = require('../services/mobileOptimizationService');

const mobileService = new MobileOptimizationService();

// Location-based attendance validation
router.post('/location/validate', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { latitude, longitude, officeLocation, maxDistance = 100 } = req.body;

    if (!latitude || !longitude || !officeLocation) {
      return res.status(400).json({
        error: 'Missing required location data',
        message: 'Please provide latitude, longitude, and office location'
      });
    }

    const userLocation = { latitude, longitude };
    const validation = mobileService.validateLocationAttendance(userLocation, officeLocation, maxDistance);

    res.json({
      success: true,
      data: validation
    });
  } catch (error) {
    console.error('Location validation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to validate location'
    });
  }
});

// Biometric authentication
router.post('/biometric/generate-token', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { deviceId } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        error: 'Missing device ID',
        message: 'Device ID is required for biometric authentication'
      });
    }

    const token = mobileService.generateBiometricToken(req.user.id, deviceId);

    res.json({
      success: true,
      data: {
        token,
        expiresIn: '5 minutes',
        deviceId
      }
    });
  } catch (error) {
    console.error('Biometric token generation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to generate biometric token'
    });
  }
});

// Verify biometric token
router.post('/biometric/verify', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { token, deviceId } = req.body;

    if (!token || !deviceId) {
      return res.status(400).json({
        error: 'Missing required data',
        message: 'Token and device ID are required'
      });
    }

    const verification = mobileService.verifyBiometricToken(token, req.user.id, deviceId);

    res.json({
      success: true,
      data: verification
    });
  } catch (error) {
    console.error('Biometric verification error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to verify biometric token'
    });
  }
});

// Get notification preferences
router.get('/notifications/preferences', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const preferences = mobileService.getNotificationPreferences(req.user.id);

    res.json({
      success: true,
      data: preferences
    });
  } catch (error) {
    console.error('Error getting notification preferences:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get notification preferences'
    });
  }
});

// Update notification preferences
router.put('/notifications/preferences', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const preferences = req.body;

    // Validate preferences structure
    if (preferences.disabledTypes && !Array.isArray(preferences.disabledTypes)) {
      return res.status(400).json({
        error: 'Invalid preferences format',
        message: 'disabledTypes must be an array'
      });
    }

    mobileService.setNotificationPreferences(req.user.id, preferences);

    res.json({
      success: true,
      message: 'Notification preferences updated successfully',
      data: mobileService.getNotificationPreferences(req.user.id)
    });
  } catch (error) {
    console.error('Error updating notification preferences:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update notification preferences'
    });
  }
});

// Optimize notification delivery
router.post('/notifications/optimize', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { notificationType, userPreferences } = req.body;

    if (!notificationType) {
      return res.status(400).json({
        error: 'Missing notification type',
        message: 'Notification type is required'
      });
    }

    const optimization = mobileService.optimizeNotificationDelivery(
      req.user.id, 
      notificationType, 
      userPreferences
    );

    // Update last notification time if sending
    if (optimization.shouldSend) {
      mobileService.updateLastNotificationTime(req.user.id, notificationType);
    }

    res.json({
      success: true,
      data: optimization
    });
  } catch (error) {
    console.error('Error optimizing notification delivery:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to optimize notification delivery'
    });
  }
});

// Generate offline token
router.post('/offline/generate-token', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { deviceId } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        error: 'Missing device ID',
        message: 'Device ID is required for offline functionality'
      });
    }

    const token = mobileService.generateOfflineToken(req.user.id, deviceId);

    res.json({
      success: true,
      data: {
        token,
        expiresIn: '24 hours',
        permissions: ['attendance', 'profile', 'leave_view'],
        deviceId
      }
    });
  } catch (error) {
    console.error('Offline token generation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to generate offline token'
    });
  }
});

// Validate offline token
router.post('/offline/validate', (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        error: 'Missing token',
        message: 'Token is required for offline validation'
      });
    }

    const validation = mobileService.validateOfflineToken(token);

    res.json({
      success: true,
      data: validation
    });
  } catch (error) {
    console.error('Offline token validation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to validate offline token'
    });
  }
});

// Touch interaction optimization
router.post('/ui/touch-targets', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { elementSize } = req.body;

    if (typeof elementSize !== 'number') {
      return res.status(400).json({
        error: 'Invalid element size',
        message: 'Element size must be a number'
      });
    }

    const optimization = mobileService.optimizeTouchTargets(elementSize);

    res.json({
      success: true,
      data: optimization
    });
  } catch (error) {
    console.error('Touch target optimization error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to optimize touch targets'
    });
  }
});

// Get mobile UI optimizations
router.post('/ui/optimizations', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    const { screenSize, platform } = req.body;

    if (!screenSize || !platform) {
      return res.status(400).json({
        error: 'Missing required data',
        message: 'Screen size and platform are required'
      });
    }

    const optimizations = mobileService.getMobileUIOptimizations(screenSize, platform);

    res.json({
      success: true,
      data: optimizations
    });
  } catch (error) {
    console.error('UI optimization error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get UI optimizations'
    });
  }
});

// Cleanup expired data (admin only)
router.delete('/cleanup', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    // Only allow admin and super_admin to perform cleanup
    if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can perform cleanup operations'
      });
    }

    mobileService.cleanup();

    res.json({
      success: true,
      message: 'Mobile optimization data cleaned up successfully'
    });
  } catch (error) {
    console.error('Cleanup error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to perform cleanup'
    });
  }
});

module.exports = router; 