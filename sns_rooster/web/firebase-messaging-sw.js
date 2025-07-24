importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Add error handling for iOS Safari compatibility
try {
  firebase.initializeApp({
    apiKey: "FIREBASE_API_KEY_PLACEHOLDER", // Replace with environment variable
    authDomain: "sns-rooster-8cca5.firebaseapp.com",
    projectId: "sns-rooster-8cca5",
    storageBucket: "sns-rooster-8cca5.appspot.com",
    messagingSenderId: "901502276055",
    appId: "1:901502276055:web:f4f94088120f52dc8f7b92",
    measurementId: "G-7QJ3X926H8"
  });

  const messaging = firebase.messaging();
  
  // Handle background messages
  messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);
    
    const notificationTitle = payload.notification?.title || 'SNS Rooster';
    const notificationOptions = {
      body: payload.notification?.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: payload.data || {}
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (error) {
  console.error('Firebase messaging service worker initialization failed:', error);
  // Continue without Firebase messaging for iOS Safari compatibility
}