import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/analytics_service.dart';
import '../firebase/crash_reporter.dart';
import '../firebase/fcm_service.dart';
import '../network/api_client.dart';
import '../network/api_error_notifier.dart';
import '../network/dio_client.dart';
import '../network/unauthorized_handler.dart';
import '../storage/local_storage.dart';
import 'di_callbacks.dart';
import 'service_locator.dart';

/// Registers app-wide services into GetIt.
///
/// GetIt: stateless services and repositories.
/// Riverpod: UI state, notifiers, and bridges into GetIt.
Future<void> configureDependencies(SharedPreferences sharedPreferences) async {
  if (getIt.isRegistered<SharedPreferences>()) {
    await getIt.reset();
  }

  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerSingleton(ApiErrorCallbackHolder());
  getIt.registerSingleton(SessionExpiredBroadcaster());

  getIt.registerLazySingleton(SecureStorageService.new);

  getIt.registerLazySingleton(
    () => PreferencesService(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton(
    () => ApiErrorNotifier(
      (error) => getIt<ApiErrorCallbackHolder>().callback?.call(error),
    ),
  );

  getIt.registerLazySingleton(
    () => UnauthorizedHandler(
      secureStorage: getIt<SecureStorageService>(),
      preferences: getIt<PreferencesService>(),
      apiErrorNotifier: getIt<ApiErrorNotifier>(),
      onSessionExpired: getIt<SessionExpiredBroadcaster>().notify,
    ),
  );

  getIt.registerLazySingleton(
    () => DioClient(
      secureStorage: getIt<SecureStorageService>(),
      unauthorizedHandler: getIt<UnauthorizedHandler>(),
    ),
  );

  getIt.registerLazySingleton(
    () => ApiClient(getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton(
    () => CrashReporter(FirebaseCrashlytics.instance),
  );

  getIt.registerLazySingleton(
    () => AnalyticsService(FirebaseAnalytics.instance),
  );

  getIt.registerLazySingleton(
    () => FcmService(
      messaging: FirebaseMessaging.instance,
      preferences: getIt<PreferencesService>(),
    ),
  );
}
