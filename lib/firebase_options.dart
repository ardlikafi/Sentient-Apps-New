// File ini berisi konfigurasi Firebase
// API Key akan diambil dari environment variables untuk keamanan

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

// Default options - akan dioverride dengan environment variables
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'your-web-api-key-here',
        ),
        authDomain: String.fromEnvironment(
          'FIREBASE_AUTH_DOMAIN',
          defaultValue: 'sentient-chess-app.firebaseapp.com',
        ),
        projectId: String.fromEnvironment(
          'FIREBASE_PROJECT_ID',
          defaultValue: 'sentient-chess-app',
        ),
        storageBucket: String.fromEnvironment(
          'FIREBASE_STORAGE_BUCKET',
          defaultValue: 'sentient-chess-app.appspot.com',
        ),
        messagingSenderId: String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
          defaultValue: '123456789012',
        ),
        appId: String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: '1:123456789012:web:abcdef123456',
        ),
        measurementId: String.fromEnvironment(
          'FIREBASE_MEASUREMENT_ID',
          defaultValue: 'G-XXXXXXXXXX',
        ),
      );
    } else {
      // Mobile configuration
      return const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'your-mobile-api-key-here',
        ),
        authDomain: 'sentient-chess-app.firebaseapp.com',
        projectId: 'sentient-chess-app',
        storageBucket: 'sentient-chess-app.appspot.com',
        messagingSenderId: '123456789012',
        appId: String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: '1:123456789012:android:abcdef123456',
        ),
        measurementId: 'G-XXXXXXXXXX',
      );
    }
  }
}
