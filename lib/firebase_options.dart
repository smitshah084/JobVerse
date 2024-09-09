// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyBFxN1qyn5DlC7aD74Icn_jVVDh1NK12Pg',
    appId: '1:296971774377:web:6f6727210796d6c7c57cb8',
    messagingSenderId: '296971774377',
    projectId: 'job-verse-db',
    authDomain: 'job-verse-db.firebaseapp.com',
    storageBucket: 'job-verse-db.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZvG1_xWxy2146PVIoFQXYhiQ8O-hKAjY',
    appId: '1:296971774377:android:e71b02265a2ad2edc57cb8',
    messagingSenderId: '296971774377',
    projectId: 'job-verse-db',
    storageBucket: 'job-verse-db.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5r83GnabzWkUdhtc0eGfwGNCveXuGXWo',
    appId: '1:65727531570:ios:e52de351ee775b5f3e8a2b',
    messagingSenderId: '65727531570',
    projectId: 'fire567',
    storageBucket: 'fire567.appspot.com',
    iosBundleId: 'com.example.fyre',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC5r83GnabzWkUdhtc0eGfwGNCveXuGXWo',
    appId: '1:65727531570:ios:e52de351ee775b5f3e8a2b',
    messagingSenderId: '65727531570',
    projectId: 'fire567',
    storageBucket: 'fire567.appspot.com',
    iosBundleId: 'com.example.fyre',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyABL68Hrh2hcDAVFU-L9LWsZ756k44X9Jo',
    appId: '1:65727531570:web:8254564ad01f67e03e8a2b',
    messagingSenderId: '65727531570',
    projectId: 'fire567',
    authDomain: 'fire567.firebaseapp.com',
    storageBucket: 'fire567.appspot.com',
  );
}