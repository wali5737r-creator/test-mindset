// ===========================================================================
//  PLACEHOLDER - Firebase is NOT configured for this project yet.
//
//  The values below are DUMMIES. Do not try to use them against a real
//  Firebase project - they will not work.
//
//  TO CONFIGURE (see README.md "Firebase setup" for the full walkthrough):
//    1. Create a Firebase project at https://console.firebase.google.com
//    2. Register the Android app with package id  com.muhammad.quizwala
//       and the Web app in that project.
//    3. Paste the real values into [web] and [android] below
//       (or run `flutterfire configure`, which rewrites this whole file).
//    4. Set [isConfigured] to true.
//    5. For Android, also drop the downloaded google-services.json into
//       android/app/ and add the google-services Gradle plugin
//       (steps are in README.md).
//
//  Until [isConfigured] is true, main.dart skips Firebase initialization
//  and the app shows a friendly "setup pending" screen instead of crashing.
// ===========================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Flip to `true` ONLY after the real values below have been pasted in.
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'QuizWala v1 targets Android and Web only. '
          'This platform has no Firebase options configured.',
        );
    }
  }

  // TODO(owner): replace every value below with the real one from the
  // Firebase console (Project settings -> Your apps -> Web app).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO-paste-web-apiKey',
    appId: 'TODO-paste-web-appId',
    messagingSenderId: 'TODO-paste-messagingSenderId',
    projectId: 'TODO-paste-projectId',
    authDomain: 'TODO-paste-projectId.firebaseapp.com',
    storageBucket: 'TODO-paste-projectId.appspot.com',
  );

  // TODO(owner): replace every value below with the real one from the
  // Firebase console (Project settings -> Your apps -> Android app).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO-paste-android-apiKey',
    appId: 'TODO-paste-android-appId',
    messagingSenderId: 'TODO-paste-messagingSenderId',
    projectId: 'TODO-paste-projectId',
    storageBucket: 'TODO-paste-projectId.appspot.com',
  );
}
