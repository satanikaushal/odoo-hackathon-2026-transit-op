import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/service_locator.dart';
import '../firebase/analytics_service.dart';
import '../firebase/crash_reporter.dart';
import '../firebase/fcm_service.dart';

final crashReporterProvider = Provider<CrashReporter>(
  (ref) => getIt<CrashReporter>(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => getIt<AnalyticsService>(),
);

final fcmServiceProvider = Provider<FcmService>(
  (ref) => getIt<FcmService>(),
);
