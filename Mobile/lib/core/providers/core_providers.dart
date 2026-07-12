import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/service_locator.dart';
import '../storage/local_storage.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => getIt<SharedPreferences>(),
);

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => getIt<SecureStorageService>(),
);

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => getIt<PreferencesService>(),
);
