const express = require('express');
const router = express.Router();
const fcmController = require('../controllers/fcm-controller');
const auth = require('../middleware/auth');

// FCM token management routes
router.post('/fcm-token', auth, fcmController.saveFCMToken);
router.get('/fcm-token/:userId?', auth, fcmController.getFCMToken);
router.delete('/fcm-token/:userId?', auth, fcmController.deleteFCMToken);

// Notification sending routes (admin only)
router.post('/send-notification', auth, fcmController.sendNotificationToUser);
router.post('/send-topic-notification', auth, fcmController.sendNotificationToTopic);
router.get('/active-tokens', auth, fcmController.getAllActiveTokens);

module.exports = router; 