const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const notificationController = require('../controllers/notification-controller');

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