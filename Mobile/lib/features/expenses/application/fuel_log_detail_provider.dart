import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/fuel_log.dart';
import 'expenses_repository_provider.dart';

class FuelLogDetailState {
  const FuelLogDetailState({
    this.log,
    this.isLoading = false,
    this.error,
  });

  final FuelLog? log;
  final bool isLoading;
  final String? error;

  FuelLogDetailState copyWith({
    FuelLog? log,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FuelLogDetailState(
      log: log ?? this.log,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FuelLogDetailNotifier
    extends AutoDisposeFamilyNotifier<FuelLogDetailState, String> {
  @override
  FuelLogDetailState build(String id) {
    ref.listen<int>(fuelLogListRefreshSignalProvider, (_, next) {
      load(id);
    });

    Future.microtask(() => load(id));
    return const FuelLogDetailState(isLoading: true);
  }

  Future<void> load(String id) async {
    if (state.log == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    final result = await ref.read(fuelLogsRepositoryProvider).fetchLog(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Fuel log not found.',
      );
      return;
    }

    state = state.copyWith(
      log: result.data,
      isLoading: false,
      clearError: true,
    );
  }
}

final fuelLogDetailProvider = AutoDisposeNotifierProviderFamily<
    FuelLogDetailNotifier, FuelLogDetailState, String>(
  FuelLogDetailNotifier.new,
);
