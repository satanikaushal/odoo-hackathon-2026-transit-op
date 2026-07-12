import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  static const _apnsMaxAttempts = 30;
  static bool _loggedApnsPending = false;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _messaging.onTokenRefresh.listen((token) async {
      await _preferences.saveFcmToken(token);
      debugPrint('[FCM] token refreshed');
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground message: ${message.messageId}');
    });

    await _refreshAndSaveToken(logOnMiss: true);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() {
    return _fetchToken(waitForApns: true);
  }

  String? get cachedToken => _preferences.fcmToken;

  Future<String?> refreshToken() {
    return _refreshAndSaveToken(logOnMiss: false);
  }

  Future<String?> _refreshAndSaveToken({required bool logOnMiss}) async {
    final token = await _fetchToken(
      waitForApns: true,
      logOnMiss: logOnMiss,
    );
    if (token != null && token.isNotEmpty) {
      await _preferences.saveFcmToken(token);
    }
    return token;
  }

  Future<String?> _fetchToken({
    required bool waitForApns,
    bool logOnMiss = false,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS && waitForApns) {
        final hasApnsToken = await _waitForApnsToken();
        if (!hasApnsToken) {
          if (logOnMiss && !_loggedApnsPending) {
            _loggedApnsPending = true;
            debugPrint(
              '[FCM] APNS token pending — FCM token will arrive via onTokenRefresh '
              '(iPhone 17 / iOS 26 simulators may need iOS 26.1+ or a physical device).',
            );
          }
          return cachedToken;
        }
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _loggedApnsPending = false;
      }
      return token ?? cachedToken;
    } on FirebaseException catch (error) {
      if (logOnMiss) {
        debugPrint('[FCM] ${error.code}: ${error.message}');
      }
      return cachedToken;
    } catch (error) {
      if (logOnMiss) {
        debugPrint('[FCM] token unavailable: $error');
      }
      return cachedToken;
    }
  }

  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsMaxAttempts; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return false;
  }
}
