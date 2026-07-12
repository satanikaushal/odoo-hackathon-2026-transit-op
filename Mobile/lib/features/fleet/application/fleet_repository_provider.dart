import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/fleet_repository.dart';

final fleetRepositoryProvider = Provider<FleetRepository>(
  (ref) => getIt<FleetRepository>(),
);

/// Bumped after mutations so the list refetches when returning from forms.
final fleetListRefreshSignalProvider = StateProvider<int>((ref) => 0);
