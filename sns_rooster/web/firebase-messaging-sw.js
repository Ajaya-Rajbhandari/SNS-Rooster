importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc",
  authDomain: "sns-rooster-8cca5.firebaseapp.com",
  projectId: "sns-rooster-8cca5",
  storageBucket: "sns-rooster-8cca5.appspot.com",
  messagingSenderId: "901502276055",
  appId: "1:901502276055:web:f4f94088120f52dc8f7b92",
  measurementId: "G-7QJ3X926H8"
});

const messaging = firebase.messaging();