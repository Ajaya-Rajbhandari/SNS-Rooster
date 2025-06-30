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

module.exports = router; 