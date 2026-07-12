import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => getIt<MaintenanceRepository>(),
);

final maintenanceListRefreshSignalProvider = StateProvider<int>((ref) => 0);
