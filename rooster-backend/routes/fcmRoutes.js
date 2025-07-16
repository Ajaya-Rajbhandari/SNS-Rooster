const express = require('express');
const router = express.Router();
const fcmController = require('../controllers/fcm-controller');
const { authenticateToken } = require('../middleware/auth');

// FCM token management routes
router.post('/fcm-token', authenticateToken, fcmController.saveFCMToken);
router.get('/fcm-token/:userId?', authenticateToken, fcmController.getFCMToken);
router.delete('/fcm-token/:userId?', authenticateToken, fcmController.deleteFCMToken);

// Notification sending routes (admin only)
router.post('/send-notification', authenticateToken, fcmController.sendNotificationToUser);
router.post('/send-topic-notification', authenticateToken, fcmController.sendNotificationToTopic);
router.get('/active-tokens', authenticateToken, fcmController.getAllActiveTokens);

module.exports = router; 