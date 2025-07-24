const admin = require('firebase-admin');

// Initialize Firebase Admin SDK using environment variables
if (!admin.apps.length) {
  try {
    // Check if environment variables are available
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      const serviceAccount = {
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      };
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      console.warn('Firebase environment variables not configured. Push notifications will be disabled.');
    }
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error);
    console.warn('Push notifications will be disabled.');
  }
}

async function sendNotificationToUser(fcmToken, title, body, data = {}) {
  try {
    if (!admin.apps.length) {
      console.warn('Firebase not initialized. Skipping push notification.');
      return;
    }
    
    const message = {
      notification: { title, body },
      data,
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
    if (!admin.apps.length) {
      console.warn('Firebase not initialized. Skipping push notification.');
      return;
    }
    
    const message = {
      notification: { title, body },
      data,
      topic,
    };
    return await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending push notification:', error);
    // Don't throw error to prevent breaking the main flow
  }
}

module.exports = {
  sendNotificationToUser,
  sendNotificationToTopic,
};
