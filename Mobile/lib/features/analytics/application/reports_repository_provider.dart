import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => getIt<ReportsRepository>(),
);

final analyticsRefreshSignalProvider = StateProvider<int>((ref) => 0);
