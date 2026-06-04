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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForInitializationOnly',
    appId: '1:108872734254:web:dummyappid',
    messagingSenderId: '108872734254',
    projectId: 'voice-calling-app-2026',
    authDomain: 'voice-calling-app-2026.firebaseapp.com',
    storageBucket: 'voice-calling-app-2026.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApPlisDVZjSuHfi4CWPUIJEeHuEuJeyas',
    appId: '1:1065507314254:android:2eeb1059e9a6aaa492c11f',
    messagingSenderId: '1065507314254',
    projectId: 'voice-calling-app-2026',
    storageBucket: 'voice-calling-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForIosInitialization',
    appId: '1:108872734254:ios:dummyappid',
    messagingSenderId: '108872734254',
    projectId: 'voice-calling-app-2026',
    storageBucket: 'voice-calling-app-2026.appspot.com',
    iosBundleId: 'com.example.flutterVoiceCallingApp2026',
  );
}