import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../data/fuel_logs_repository.dart';
import '../data/expenses_repository.dart';

final fuelLogsRepositoryProvider = Provider<FuelLogsRepository>(
  (ref) => getIt<FuelLogsRepository>(),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => getIt<ExpensesRepository>(),
);

final fuelLogListRefreshSignalProvider = StateProvider<int>((ref) => 0);

final expenseListRefreshSignalProvider = StateProvider<int>((ref) => 0);
