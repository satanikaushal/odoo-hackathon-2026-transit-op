import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for TransitOps mobile apps.
///
/// Generated manually from `google-services.json` and `GoogleService-Info.plist`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      TargetPlatform.windows => throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        ),
      TargetPlatform.linux => throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        ),
      TargetPlatform.fuchsia => throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQLRhTQuAD-gSGV2yFch_gpNpLaWtoSWI',
    appId: '1:411935298548:android:b6ff56a14c0c30fe88dfa1',
    messagingSenderId: '411935298548',
    projectId: 'transit-op-odoo-hackathon-2026',
    storageBucket: 'transit-op-odoo-hackathon-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBbD15Ss3oalrYgvVO-SVfdCx1wESu2Ni8',
    appId: '1:411935298548:ios:4cf013f66e4d970888dfa1',
    messagingSenderId: '411935298548',
    projectId: 'transit-op-odoo-hackathon-2026',
    storageBucket: 'transit-op-odoo-hackathon-2026.firebasestorage.app',
    iosBundleId: 'com.transit.ops.app',
  );
}
