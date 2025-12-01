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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNeaL0hk1xFLIpvGsJ45-EbSM8V3uUsNg',
    appId: '1:256204824178:android:e0ee4c92a6160886a6aceb',
    messagingSenderId: '256204824178',
    projectId: 'app-2jem-v2',
    storageBucket: 'app-2jem-v2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvTLuNqqcra7T04Jm9_ojC1Uw-9Hnj2IU',
    appId: '1:256204824178:ios:76d115763bf1542da6aceb',
    messagingSenderId: '256204824178',
    projectId: 'app-2jem-v2',
    storageBucket: 'app-2jem-v2.firebasestorage.app',
    iosBundleId: 'com.example.app2jem',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUmwlUKOq_mCfQRXic-0LGK6b_idH-wjk',
    appId: '1:256204824178:web:33ef4b014ab59219a6aceb',
    messagingSenderId: '256204824178',
    projectId: 'app-2jem-v2',
    authDomain: 'app-2jem-v2.firebaseapp.com',
    storageBucket: 'app-2jem-v2.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvTLuNqqcra7T04Jm9_ojC1Uw-9Hnj2IU',
    appId: '1:256204824178:ios:76d115763bf1542da6aceb',
    messagingSenderId: '256204824178',
    projectId: 'app-2jem-v2',
    storageBucket: 'app-2jem-v2.firebasestorage.app',
    iosBundleId: 'com.example.app2jem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBUmwlUKOq_mCfQRXic-0LGK6b_idH-wjk',
    appId: '1:256204824178:web:faafe5b761bcc8b9a6aceb',
    messagingSenderId: '256204824178',
    projectId: 'app-2jem-v2',
    authDomain: 'app-2jem-v2.firebaseapp.com',
    storageBucket: 'app-2jem-v2.firebasestorage.app',
  );

}