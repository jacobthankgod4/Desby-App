import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseOptionsProvider {
  FirebaseOptionsProvider._();

  static FirebaseOptions get options {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyAjBtzLr8hE4R2_I-uYvwOC5MtME8Fe9Fg',
        appId: '1:436814609100:web:f52d5fbaf4d8674f67e069',
        messagingSenderId: '436814609100',
        projectId: 'desby-os',
        authDomain: 'desby-os.firebaseapp.com',
        storageBucket: 'desby-os.firebasestorage.app',
      );
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAjBtzLr8hE4R2_I-uYvwOC5MtME8Fe9Fg',
          appId: '1:436814609100:android:94227a5e7cb6536f67e069',
          messagingSenderId: '436814609100',
          projectId: 'desby-os',
          storageBucket: 'desby-os.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAG6H83vMmQh_1K4iOpglOa3uOV9Bv4go8',
          appId: '1:436814609100:ios:ac00975e2a1427c067e069',
          messagingSenderId: '436814609100',
          projectId: 'desby-os',
          storageBucket: 'desby-os.firebasestorage.app',
          iosBundleId: 'com.desby.app',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAG6H83vMmQh_1K4iOpglOa3uOV9Bv4go8',
          appId: '1:436814609100:macos:5e7cb6536f67e069',
          messagingSenderId: '436814609100',
          projectId: 'desby-os',
          storageBucket: 'desby-os.firebasestorage.app',
          iosBundleId: 'com.desby.app',
        );
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }
}
