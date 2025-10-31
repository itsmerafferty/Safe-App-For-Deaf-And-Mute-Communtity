// This file should be replaced with your actual Firebase configuration
// To get this file:
// 1. Go to https://console.firebase.google.com/
// 2. Create a new project or select existing project
// 3. Add a Flutter app to your project
// 4. Download the generated firebase_options.dart file
// 5. Replace this file with the downloaded file

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example configuration - replace with your actual Firebase config
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
        return windows;
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
    apiKey: 'AIzaSyDv6GRzR9Zm5aRBJixmFpIAe0kxmR56PRM',
    appId: '1:931268241347:android:128118209c0aa1fd4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD4MlUDKJR5emNururXZYafjf9I3MAh3Ak',
    appId: '1:931268241347:ios:a536fc3fa15e15da4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.firebasestorage.app',
    iosBundleId: 'com.example.safeApplicationForDeafandmute',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD4MlUDKJR5emNururXZYafjf9I3MAh3Ak',
    appId: '1:931268241347:ios:a536fc3fa15e15da4c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    storageBucket: 'safe-emergency-app-f4c17.firebasestorage.app',
    iosBundleId: 'com.example.safeApplicationForDeafandmute',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCwx4-9Gt4FSkRSzAZHgrFTVQIRJo-qlcs',
    appId: '1:931268241347:web:280fce0ea2c2b0884c3f76',
    messagingSenderId: '931268241347',
    projectId: 'safe-emergency-app-f4c17',
    authDomain: 'safe-emergency-app-f4c17.firebaseapp.com',
    storageBucket: 'safe-emergency-app-f4c17.firebasestorage.app',
    measurementId: 'G-GKRV1VY02H',
  );

}