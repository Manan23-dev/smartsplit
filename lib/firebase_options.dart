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
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCVC80oJMhz13PzmkaV-unmWtaVT5fKqG4',
    appId: '1:224743645424:web:5bb830019643dcabc8a235',
    messagingSenderId: '224743645424',
    projectId: 'smartsplit-expensetracker',
    authDomain: 'smartsplit-expensetracker.firebaseapp.com',
    storageBucket: 'smartsplit-expensetracker.firebasestorage.app',
    measurementId: 'G-7HV8RSHQBC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBl36KnCSXv6z9UnoINTBVVM_VCbLWRY-Y',
    appId: '1:224743645424:android:d64b6df6707cbf44c8a235',
    messagingSenderId: '224743645424',
    projectId: 'smartsplit-expensetracker',
    storageBucket: 'smartsplit-expensetracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0xm3amGmwyHvzMuy-jSMk5uNPChrnrRU',
    appId: '1:224743645424:ios:c57c7cc71b6b0744c8a235',
    messagingSenderId: '224743645424',
    projectId: 'smartsplit-expensetracker',
    storageBucket: 'smartsplit-expensetracker.firebasestorage.app',
    iosBundleId: 'com.example.smartsplit',
  );

}