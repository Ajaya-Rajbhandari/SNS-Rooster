const admin = require('firebase-admin');
const Notification = require('../models/Notification');

// Initialize Firebase Admin SDK using environment variables
if (!admin.apps.length) {
  try {
    console.log('DEBUG: FCM - Initializing Firebase Admin SDK...');
    console.log('DEBUG: FCM - Environment variables check:');
    console.log('  FIREBASE_PROJECT_ID:', process.env.FIREBASE_PROJECT_ID ? 'SET' : 'NOT SET');
    console.log('  FIREBASE_PRIVATE_KEY:', process.env.FIREBASE_PRIVATE_KEY ? 'SET' : 'NOT SET');
    console.log('  FIREBASE_CLIENT_EMAIL:', process.env.FIREBASE_CLIENT_EMAIL ? 'SET' : 'NOT SET');
    
    // Check if environment variables are available
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      const serviceAccount = {
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      };
      
      console.log('DEBUG: FCM - Service account configured, initializing...');
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      
      console.log('DEBUG: FCM - Firebase Admin SDK initialized successfully');
    } else {
      console.warn('Firebase environment variables not configured. Push notifications will be disabled.');
    }
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error);
    console.warn('Push notifications will be disabled.');
  }
} else {
  console.log('DEBUG: FCM - Firebase Admin SDK already initialized');
}

async function sendNotificationToUser(fcmToken, title, body, data = {}, userId = null) {
  try {
    // Input validation
    if (!title || !body) {
      throw new Error('Title and body are required for notifications');
    }

    if (!fcmToken) {
      throw new Error('FCM token is required for sending notifications');
    }

    // Save notification to database if userId is provided
    if (userId) {
      try {
        const notification = new Notification({
          userId,
          title,
          body,
          data,
          status: 'pending', // Track notification status
          attempts: 0, // Track retry attempts
          createdAt: new Date(),
        });
        await notification.save();
        console.log('DEBUG: FCM - Notification saved to database for user:', userId);
      } catch (dbError) {
        console.error('Error saving notification to database:', {
          error: dbError.message,
          stack: dbError.stack,
          userId,
          title,
          type: data.type || 'unknown'
        });
        // Continue with FCM even if DB save fails
      }
    }

    if (!admin.apps.length) {
      console.warn('Firebase not initialized. Skipping push notification.');
      return;
    }
    
    // Convert all data values to strings (Firebase requirement)
    const stringData = {};
    Object.keys(data).forEach(key => {
      stringData[key] = String(data[key]);
    });
    
    console.log('DEBUG: FCM - Sending notification to user');
    console.log('DEBUG: FCM - Token:', fcmToken ? fcmToken.substring(0, 20) + '...' : 'null');
    console.log('DEBUG: FCM - Title:', title);
    console.log('DEBUG: FCM - Body:', body);
    console.log('DEBUG: FCM - Data:', stringData);
    
    const message = {
      notification: { title, body },
      data: stringData,
      token: fcmToken,
    };
    return await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending push notification:', error);
    // Don't throw error to prevent breaking the main flow
  }
}

async function sendNotificationToTopic(topic, title, body, data = {}) {
  try {
    console.log('DEBUG: FCM - Attempting to send topic notification');
    console.log('DEBUG: FCM - Topic:', topic);
    console.log('DEBUG: FCM - Title:', title);
    console.log('DEBUG: FCM - Body:', body);
    console.log('DEBUG: FCM - Data:', data);
    
    if (!admin.apps.length) {
      console.warn('Firebase not initialized. Skipping push notification.');
      return;
    }
    
    // Convert all data values to strings (Firebase requirement)
    const stringData = {};
    Object.keys(data).forEach(key => {
      stringData[key] = String(data[key]);
    });
    
    console.log('DEBUG: FCM - Firebase is initialized, sending message...');
    
    const message = {
      notification: { title, body },
      data: stringData,
      topic,
    };
    
    console.log('DEBUG: FCM - Message object:', message);
    
    const result = await admin.messaging().send(message);
    console.log('DEBUG: FCM - Message sent successfully:', result);
    return result;
  } catch (error) {
    console.error('DEBUG: FCM - Error sending push notification:', error);
    console.error('DEBUG: FCM - Error details:', {
      code: error.code,
      message: error.message,
      stack: error.stack
    });
    // Don't throw error to prevent breaking the main flow
  }
}

module.exports = {
  sendNotificationToUser,
  sendNotificationToTopic,
};
