// reference https://www.youtube.com/watch?v=FQ61dZ9435s
// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyDYXiiHxaDIUBoMr5z9y7-ip_yc8OFcvJA",
  authDomain: "apviser-72c4e.firebaseapp.com",
  databaseURL: "https://apviser-72c4e.firebaseio.com",
  projectId: "apviser-72c4e",
  storageBucket: "apviser-72c4e.appspot.com",
  messagingSenderId: "453905060766",
  appId: "1:453905060766:web:09129efcfc43ba5e29fc8f"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});