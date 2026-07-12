import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/drivers_repository.dart';

final driversRepositoryProvider = Provider<DriversRepository>(
  (ref) => getIt<DriversRepository>(),
);

final driverListRefreshSignalProvider = StateProvider<int>((ref) => 0);
