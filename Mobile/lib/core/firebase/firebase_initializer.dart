import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../../firebase_options.dart';
import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'fcm_service.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<void> init({
    required CrashReporter crashReporter,
    required AnalyticsService analyticsService,
    required FcmService fcmService,
  }) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final isDev = AppEnvironment.current.env == Env.DEV;

    await crashReporter.configure(enabled: !isDev);
    await analyticsService.configure(enabled: !isDev);
    await fcmService.init();

    if (!isDev) {
      FlutterError.onError = crashReporter.recordFlutterError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashReporter.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }
}
