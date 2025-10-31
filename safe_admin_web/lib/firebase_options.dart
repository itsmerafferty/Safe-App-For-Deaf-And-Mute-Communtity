import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwx4-9Gt4FSkRSzAZHgrFTVQIRJo-qlcs',
    appId: '1:931268241347:web:73de2d3fb0949cbf4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    authDomain: 'safe-emergency-app-f4c17.firebaseapp.com',
    storageBucket: 'safe-emergency-app-f4c17.firebasestorage.app',
    measurementId: 'G-ECG5MGB0GP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:931268241347:android:128118209c0aa1fd4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:931268241347:ios:a536fc3fa15e15da4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.appspot.com',
    iosBundleId: 'com.example.safeApplicationForDeafandmute',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:931268241347:ios:a536fc3fa15e15da4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.appspot.com',
    iosBundleId: 'com.example.safeApplicationForDeafandmute',
  );
}
