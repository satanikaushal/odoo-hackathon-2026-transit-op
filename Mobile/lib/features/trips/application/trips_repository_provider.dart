import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/trips_repository.dart';

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => getIt<TripsRepository>(),
);

final tripListRefreshSignalProvider = StateProvider<int>((ref) => 0);
