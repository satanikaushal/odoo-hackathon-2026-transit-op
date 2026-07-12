import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required PreferencesService preferences,
  })  : _messaging = messaging,
        _preferences = preferences;

  final FirebaseMessaging _messaging;
  final PreferencesService _preferences;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _refreshAndSaveToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _preferences.saveFcmToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  String? get cachedToken => _preferences.fcmToken;

  Future<String?> refreshToken() => _refreshAndSaveToken();

  Future<String?> _refreshAndSaveToken() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _preferences.saveFcmToken(token);
    }
    return token;
  }
}
