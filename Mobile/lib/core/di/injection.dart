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
import '../../features/auth/data/auth_token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/token_refresh_service.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/fleet/data/fleet_repository.dart';
import '../../features/drivers/data/drivers_repository.dart';
import '../../features/trips/data/trips_repository.dart';
import '../../features/maintenance/data/maintenance_repository.dart';
import '../../features/analytics/data/reports_repository.dart';
import '../../features/expenses/data/fuel_logs_repository.dart';
import '../../features/expenses/data/expenses_repository.dart';
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
    () => AuthTokenStorage(getIt<SecureStorageService>()),
  );

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
      tokenStorage: getIt<AuthTokenStorage>(),
    ),
  );

  getIt.registerLazySingleton(
    () => getIt<DioClient>().tokenRefreshService,
  );

  getIt.registerLazySingleton(
    () => ApiClient(getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton(
    () => AuthRepository(
      apiClient: getIt<ApiClient>(),
      tokenStorage: getIt<AuthTokenStorage>(),
      preferences: getIt<PreferencesService>(),
      fcmService: getIt<FcmService>(),
      tokenRefreshService: getIt<TokenRefreshService>(),
    ),
  );

  getIt.registerLazySingleton(
    () => DashboardRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => FleetRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => DriversRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => TripsRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => MaintenanceRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => ReportsRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => FuelLogsRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton(
    () => ExpensesRepository(apiClient: getIt<ApiClient>()),
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
