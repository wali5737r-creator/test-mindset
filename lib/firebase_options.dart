// Firebase options for Test Mindset.
//
// ANDROID: configured 2026-11-27 from the owner's google-services.json
// (project test-mindset-4c595). The same values live in android/app/google-services.json.
//
// WEB: configured 2026-11-27 from the owner-registered Web app.
// (values below; measurementId is not used by Flutter).
// While a platform is unconfigured, [isConfigured] is false there and the app shows the friendly
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

  // Web app values: filled 2026-11-27 from the owner's Firebase console
  // config (app Test Mindset Web).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8BkF_K5d3QJMjoX-k54dH-Cz-KcbYISM',
    appId: '1:679331143087:web:8b872db5d6c4873743235a',
    messagingSenderId: '679331143087',
    projectId: 'test-mindset-4c595',
    authDomain: 'test-mindset-4c595.firebaseapp.com',
    storageBucket: 'test-mindset-4c595.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClygtN-YXo3yRi1RHGJltKXTD1pOdJu5M',
    appId: '1:679331143087:android:03387a6467654e8343235a',
    messagingSenderId: '679331143087',
    projectId: 'test-mindset-4c595',
    storageBucket: 'test-mindset-4c595.firebasestorage.app',
  );
}
