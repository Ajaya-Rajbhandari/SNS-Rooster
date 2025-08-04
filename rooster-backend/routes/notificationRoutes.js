const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification-controller');
const { authenticateToken } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// Get notifications for current user
router.get('/', notificationController.getNotifications);

// Create a new notification (for system use)
router.post('/', notificationController.createNotification);

// Mark notification as read
router.patch('/:id/read', notificationController.markAsRead);

// Mark all notifications as read
router.patch('/mark-all-read', notificationController.markAllAsRead);

// Delete a notification
router.delete('/:id', notificationController.deleteNotification);

// Delete all notifications for user
router.delete('/', notificationController.deleteAllNotifications);

module.exports = router; 