// Firebase options for Test Mindset.
//
// ANDROID: configured 2026-11-27 from the owner's google-services.json
// (project test-mindset-4c595). The same values live in android/app/google-services.json.
//
// WEB: still TODO - the owner registers the Web app in the Firebase console
// next; paste its values into [web] below (or run `flutterfire configure`).
// Until then [isConfigured] is false on web and the app shows the friendly
// "setup pending" screen there instead of crashing.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// True when the CURRENT platform has real (non-TODO) values filled in.
  static bool get isConfigured {
    if (kIsWeb) {
      return !web.appId.startsWith('TODO');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return !android.appId.startsWith('TODO');
    }
    return false;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Test Mindset v1 targets Android and Web only. '
          'This platform has no Firebase options configured.',
        );
    }
  }

  // TODO(owner): replace with the Web app values from the Firebase console
  // (Project settings -> Your apps -> Web app).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO-paste-web-apiKey',
    appId: 'TODO-paste-web-appId',
    messagingSenderId: 'TODO-paste-messagingSenderId',
    projectId: 'TODO-paste-projectId',
    authDomain: 'TODO-paste-projectId.firebaseapp.com',
    storageBucket: 'TODO-paste-projectId.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClygtN-YXo3yRi1RHGJltKXTD1pOdJu5M',
    appId: '1:679331143087:android:03387a6467654e8343235a',
    messagingSenderId: '679331143087',
    projectId: 'test-mindset-4c595',
    storageBucket: 'test-mindset-4c595.firebasestorage.app',
  );
}
