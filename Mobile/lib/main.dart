import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/di/injection.dart';
import 'core/di/service_locator.dart';
import 'core/firebase/analytics_service.dart';
import 'core/firebase/crash_reporter.dart';
import 'core/firebase/fcm_service.dart';
import 'core/firebase/firebase_initializer.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnvironment.setUp(Env.DEV);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  await configureDependencies(sharedPreferences);

  await FirebaseInitializer.init(
    crashReporter: getIt<CrashReporter>(),
    analyticsService: getIt<AnalyticsService>(),
    fcmService: getIt<FcmService>(),
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
