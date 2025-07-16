const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const notificationController = require('../controllers/notification-controller');

// Create a notification (admin/system)
router.post('/', authenticateToken, notificationController.createNotification);

// List notifications for current user
router.get('/', authenticateToken, notificationController.getNotifications);

// Mark notification as read
router.patch('/:id/read', authenticateToken, notificationController.markAsRead);

// Mark all notifications as read
router.patch('/mark-all-read', authenticateToken, notificationController.markAllAsRead);

// Delete all notifications for the current user/role
router.delete('/clear-all', authenticateToken, notificationController.clearAllNotifications);

// Delete a single notification by ID
router.delete('/:id', authenticateToken, notificationController.deleteNotification);

// Admin-only: delete all admin notifications
router.delete('/clear-all-admin', authenticateToken, notificationController.clearAllAdminNotifications);

module.exports = router; 