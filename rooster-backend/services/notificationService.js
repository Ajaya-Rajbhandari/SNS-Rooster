const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../firebase-adminsdk.json'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function sendNotificationToUser(fcmToken, title, body, data = {}) {
  const message = {
    notification: { title, body },
    data,
    token: fcmToken,
  };
  return admin.messaging().send(message);
}

async function sendNotificationToTopic(topic, title, body, data = {}) {
  const message = {
    notification: { title, body },
    data,
    topic,
  };
  return admin.messaging().send(message);
}

module.exports = {
  sendNotificationToUser,
  sendNotificationToTopic,
};
