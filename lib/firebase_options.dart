// File generated for the SpotVibe Firebase project (spotvibe-cfa08).
//
// The Web config below is the real project configuration. The Android and
// iOS configs must be generated on your machine with the FlutterFire CLI so
// they include your native app registrations:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=spotvibe-cfa08
//
// That command rewrites this file with the android/ios/macOS options and
// also downloads google-services.json / GoogleService-Info.plist.
//
// NOTE: the Android app must be registered in the Firebase console with
// package name `app.spotvibe` (the rebranded applicationId), and iOS with
// bundle id `app.spotvibe`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Firebase Android is not configured yet.\n'
          'Run on your machine:  flutterfire configure --project=spotvibe-cfa08\n'
          '(registers package app.spotvibe and rewrites this file)',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase iOS is not configured yet.\n'
          'Run on your machine:  flutterfire configure --project=spotvibe-cfa08\n'
          '(registers bundle id app.spotvibe and rewrites this file)',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0YGK4QmFutRxlrFcTz6XjX5oBO52hvmw',
    appId: '1:626183324233:web:db73096904c2fc41d8f598',
    messagingSenderId: '626183324233',
    projectId: 'spotvibe-cfa08',
    authDomain: 'spotvibe-cfa08.firebaseapp.com',
    storageBucket: 'spotvibe-cfa08.firebasestorage.app',
    measurementId: 'G-EH93TGPPS1',
  );
}
