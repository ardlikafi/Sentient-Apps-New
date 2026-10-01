// File ini berisi konfigurasi Firebase
// API Key diambil dari file google-services.json asli untuk konektivitas langsung

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration (menggunakan data dari sentient-chess-app)
      return const FirebaseOptions(
        apiKey: 'AIzaSyCzlL748dlENTA_qzNcAA5lJuO6SzIM6OE',
        authDomain: 'sentient-chess-app.firebaseapp.com',
        projectId: 'sentient-chess-app',
        storageBucket: 'sentient-chess-app.firebasestorage.app',
        messagingSenderId: '815651012630',
        appId: '1:815651012630:web:abcdef123456', // default web placeholder
        measurementId: 'G-XXXXXXXXXX',
      );
    } else {
      // Mobile configuration (diambil langsung dari android/app/google-services.json)
      return const FirebaseOptions(
        apiKey: 'AIzaSyCzlL748dlENTA_qzNcAA5lJuO6SzIM6OE',
        authDomain: 'sentient-chess-app.firebaseapp.com',
        projectId: 'sentient-chess-app',
        storageBucket: 'sentient-chess-app.firebasestorage.app',
        messagingSenderId: '815651012630',
        appId: '1:815651012630:android:37c12e54792f9e2d3ff537',
        measurementId: 'G-XXXXXXXXXX',
      );
    }
  }
}
