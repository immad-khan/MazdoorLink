// File generated manually from google-services.json + Firebase console web config.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2lYOMEOx0iboiziHumRKWfa9RWVpMS9E',
    authDomain: 'mazdoorlink-30879.firebaseapp.com',
    projectId: 'mazdoorlink-30879',
    storageBucket: 'mazdoorlink-30879.firebasestorage.app',
    messagingSenderId: '182267491420',
    appId: '1:182267491420:web:d0e21ef1d5aab6950fe299', // ⚠️ Replace with real web appId from Firebase Console → Project Settings → Your apps → Web app
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2lYOMEOx0iboiziHumRKWfa9RWVpMS9E',
    authDomain: 'mazdoorlink-30879.firebaseapp.com',
    projectId: 'mazdoorlink-30879',
    storageBucket: 'mazdoorlink-30879.firebasestorage.app',
    messagingSenderId: '182267491420',
    appId: '1:182267491420:android:d0e21ef1d5aab6950fe299',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2lYOMEOx0iboiziHumRKWfa9RWVpMS9E',
    authDomain: 'mazdoorlink-30879.firebaseapp.com',
    projectId: 'mazdoorlink-30879',
    storageBucket: 'mazdoorlink-30879.firebasestorage.app',
    messagingSenderId: '182267491420',
    appId: '1:182267491420:ios:d0e21ef1d5aab6950fe299', // ⚠️ Replace with real iOS appId if needed
  );
}
