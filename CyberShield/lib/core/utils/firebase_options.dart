import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        return ios;

      case TargetPlatform.macOS:
        return macos;

      case TargetPlatform.windows:
        return windows;

      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkzcFbYEd-USWjQhxu73DNa6DeF4NaG4U',
    appId: '1:350128910277:android:c6d26a38e8c75adcf2e5ac',
    messagingSenderId: '350128910277',
    projectId: 'cybershield-4e3ed',
    storageBucket: 'cybershield-4e3ed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAf142pBnYYqloaohDAsyuTRUZFX9uaVfU',
    appId: '1:350128910277:ios:b8ee68ed74b9e20ff2e5ac',
    messagingSenderId: '350128910277',
    projectId: 'cybershield-4e3ed',
    storageBucket: 'cybershield-4e3ed.firebasestorage.app',
    iosBundleId: 'com.example.shibershieldProjectspace',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAf142pBnYYqloaohDAsyuTRUZFX9uaVfU',
    appId: '1:350128910277:ios:b8ee68ed74b9e20ff2e5ac',
    messagingSenderId: '350128910277',
    projectId: 'cybershield-4e3ed',
    storageBucket: 'cybershield-4e3ed.firebasestorage.app',
    iosBundleId: 'com.example.shibershieldProjectspace',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDeuXwpEVBDvvXIcESDM07dl6o2dL8f_M0',
    appId: '1:350128910277:web:d0ca42c6d5079a22f2e5ac',
    messagingSenderId: '350128910277',
    projectId: 'cybershield-4e3ed',
    authDomain: 'cybershield-4e3ed.firebaseapp.com',
    storageBucket: 'cybershield-4e3ed.firebasestorage.app',
  );
}