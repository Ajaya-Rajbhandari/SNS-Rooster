const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const notificationController = require('../controllers/notification-controller');

// Create a notification (admin/system)
router.post('/', auth, notificationController.createNotification);

// List notifications for current user
router.get('/', auth, notificationController.getNotifications);

// Mark notification as read
router.patch('/:id/read', auth, notificationController.markAsRead);

// Mark all notifications as read
router.patch('/mark-all-read', auth, notificationController.markAllAsRead);

// Delete all notifications for the current user/role
router.delete('/clear-all', auth, notificationController.clearAllNotifications);

// Delete a single notification by ID
router.delete('/:id', auth, notificationController.deleteNotification);

module.exports = router; 