const FCMToken = require('../models/FCMToken');
const User = require('../models/User');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let firebaseApp;
try {
  // Check if Firebase is already initialized
  firebaseApp = admin.app();
} catch (error) {
  // Initialize Firebase Admin SDK
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Use environment variable (for cloud deployment)
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else {
    // Use local file (for development)
    try {
      const serviceAccount = require('../serviceAccountKey.json');
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    } catch (fileError) {
      console.warn('Firebase Admin SDK not initialized - service account not found');
    }
  }
}

// Save FCM token for a user
exports.saveFCMToken = async (req, res) => {
  try {
    const { fcmToken, userId } = req.body;
    const requestingUserId = req.user.id;

    // Validate input
    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    // Ensure user can only save their own token
    if (userId && userId !== requestingUserId) {
      return res.status(403).json({ message: 'Unauthorized to save token for another user' });
    }

    const targetUserId = userId || requestingUserId;

    // Check if user exists
    const user = await User.findById(targetUserId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Save or update FCM token
    const tokenData = {
      userId: targetUserId,
      fcmToken,
      deviceInfo: {
        platform: req.body.platform || 'unknown',
        appVersion: req.body.appVersion || '1.0.0',
        deviceModel: req.body.deviceModel || 'unknown'
      },
      lastUsed: new Date()
    };

    await FCMToken.findOneAndUpdate(
      { userId: targetUserId },
      tokenData,
      { upsert: true, new: true }
    );

    res.status(200).json({ message: 'FCM token saved successfully' });
  } catch (error) {
    console.error('Error saving FCM token:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Get FCM token for a user
exports.getFCMToken = async (req, res) => {
  try {
    const userId = req.params.userId || req.user.id;

    // Ensure user can only get their own token
    if (req.params.userId && req.params.userId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized to access another user\'s token' });
    }

    const fcmToken = await FCMToken.findOne({ userId, isActive: true });
    
    if (!fcmToken) {
      return res.status(404).json({ message: 'FCM token not found' });
    }

    res.status(200).json({ fcmToken: fcmToken.fcmToken });
  } catch (error) {
    console.error('Error getting FCM token:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Delete FCM token for a user
exports.deleteFCMToken = async (req, res) => {
  try {
    const userId = req.params.userId || req.user.id;

    // Ensure user can only delete their own token
    if (req.params.userId && req.params.userId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized to delete another user\'s token' });
    }

    await FCMToken.findOneAndUpdate(
      { userId },
      { isActive: false },
      { new: true }
    );

    res.status(200).json({ message: 'FCM token deleted successfully' });
  } catch (error) {
    console.error('Error deleting FCM token:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Send notification to specific user
exports.sendNotificationToUser = async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;

    // Validate input
    if (!userId || !title || !body) {
      return res.status(400).json({ message: 'userId, title, and body are required' });
    }

    // Get user's FCM token
    const fcmTokenDoc = await FCMToken.findOne({ userId, isActive: true });
    if (!fcmTokenDoc) {
      return res.status(404).json({ message: 'User FCM token not found' });
    }

    // Prepare notification message
    const message = {
      token: fcmTokenDoc.fcmToken,
      notification: {
        title,
        body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'sns_rooster_channel',
          priority: 'high',
          defaultSound: true
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    // Send notification (requires Firebase Admin SDK)
    if (firebaseApp) {
      try {
        const response = await admin.messaging().send(message);
        console.log('Notification sent successfully:', response);
      } catch (error) {
        console.error('Error sending notification:', error);
        return res.status(500).json({ message: 'Failed to send notification' });
      }
    } else {
      console.log('Firebase Admin SDK not initialized - notification message prepared:', message);
    }

    res.status(200).json({ message: 'Notification sent successfully' });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Send notification to topic
exports.sendNotificationToTopic = async (req, res) => {
  try {
    const { topic, title, body, data } = req.body;

    // Validate input
    if (!topic || !title || !body) {
      return res.status(400).json({ message: 'topic, title, and body are required' });
    }

    // Prepare notification message
    const message = {
      topic,
      notification: {
        title,
        body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'sns_rooster_channel',
          priority: 'high',
          defaultSound: true
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    // Send notification (requires Firebase Admin SDK)
    if (firebaseApp) {
      try {
        const response = await admin.messaging().send(message);
        console.log('Topic notification sent successfully:', response);
      } catch (error) {
        console.error('Error sending topic notification:', error);
        return res.status(500).json({ message: 'Failed to send topic notification' });
      }
    } else {
      console.log('Firebase Admin SDK not initialized - topic notification message prepared:', message);
    }

    res.status(200).json({ message: 'Topic notification sent successfully' });
  } catch (error) {
    console.error('Error sending topic notification:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Get all active FCM tokens (admin only)
exports.getAllActiveTokens = async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const tokens = await FCMToken.find({ isActive: true })
      .populate('userId', 'name email role')
      .select('-fcmToken'); // Don't expose actual tokens

    res.status(200).json({ tokens });
  } catch (error) {
    console.error('Error getting active tokens:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
}; 