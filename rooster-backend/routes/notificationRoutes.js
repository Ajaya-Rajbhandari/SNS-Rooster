const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const notificationController = require('../controllers/notification-controller');

// Simple notification endpoints (for testing)
router.get('/simple', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple notifications endpoint hit');
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling getNotifications with companyId:', req.companyId);
    const result = await notificationController.getNotifications(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple notifications endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notifications',
      error: error.message
    });
  }
});

router.get('/simple/unread-count', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple unread count endpoint hit');
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    const result = await notificationController.getUnreadCount(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple unread count endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching unread count',
      error: error.message
    });
  }
});

// Create a notification (admin/system)
router.post('/', authenticateToken, notificationController.createNotification);

// List notifications for current user
router.get('/', authenticateToken, notificationController.getNotifications);

// Mark notification as read
router.patch('/:id/read', authenticateToken, notificationController.markAsRead);

// Mark all notifications as read
router.patch('/mark-all-read', authenticateToken, notificationController.markAllAsRead);

// Get unread notification count
router.get('/unread-count', authenticateToken, notificationController.getUnreadCount);

// Delete all notifications for the current user/role
router.delete('/clear-all', authenticateToken, notificationController.clearAllNotifications);

// Delete a single notification by ID
router.delete('/:id', authenticateToken, notificationController.deleteNotification);

// Admin-only: delete all admin notifications
router.delete('/clear-all-admin', authenticateToken, notificationController.clearAllAdminNotifications);

// Get company notifications/updates for employees
router.get('/company', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    // Mock company notifications - in a real app, this would come from a database
    const notifications = [
      {
        _id: '1',
        title: 'System Maintenance',
        message: 'Scheduled maintenance on Sunday, 2:00 AM - 4:00 AM. The system will be temporarily unavailable.',
        type: 'maintenance',
        priority: 'normal',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 days ago
        companyId: req.companyId,
      },
      {
        _id: '2',
        title: 'New Feature Available',
        message: 'Location-based attendance tracking is now live! You can now clock in/out using GPS location.',
        type: 'feature',
        priority: 'high',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(), // 1 week ago
        companyId: req.companyId,
      },
      {
        _id: '3',
        title: 'Holiday Notice',
        message: 'Office will be closed on December 25th for Christmas. Please plan your work accordingly.',
        type: 'holiday',
        priority: 'high',
        createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(), // 2 weeks ago
        companyId: req.companyId,
      },
      {
        _id: '4',
        title: 'Monthly Team Meeting',
        message: 'Monthly team meeting scheduled for Friday at 3:00 PM. All employees are required to attend.',
        type: 'announcement',
        priority: 'normal',
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(), // 1 day ago
        companyId: req.companyId,
      },
    ];

    res.json({
      success: true,
      notifications: notifications,
      count: notifications.length
    });
  } catch (error) {
    console.error('Error fetching company notifications:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch company notifications',
      message: error.message
    });
  }
});

module.exports = router; 