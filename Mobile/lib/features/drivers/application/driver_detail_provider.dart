import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/driver.dart';
import '../domain/models/driver_status.dart';
import 'drivers_repository_provider.dart';

class DriverDetailState {
  const DriverDetailState({
    this.driver,
    this.isLoading = false,
    this.error,
    this.isMutating = false,
  });

  final Driver? driver;
  final bool isLoading;
  final String? error;
  final bool isMutating;

  DriverDetailState copyWith({
    Driver? driver,
    bool? isLoading,
    String? error,
    bool? isMutating,
    bool clearError = false,
  }) {
    return DriverDetailState(
      driver: driver ?? this.driver,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class DriverDetailNotifier
    extends AutoDisposeFamilyNotifier<DriverDetailState, String> {
  @override
  DriverDetailState build(String id) {
    ref.listen<int>(driverListRefreshSignalProvider, (_, next) {
      load(id);
    });

    Future.microtask(() => load(id));
    return const DriverDetailState(isLoading: true);
  }

  Future<void> load(String id) async {
    if (state.driver == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    final result = await ref.read(driversRepositoryProvider).fetchDriver(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Driver not found.',
      );
      return;
    }

    state = state.copyWith(
      driver: result.data,
      isLoading: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> updateStatus(
    String id,
    DriverStatus status,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final driver = state.driver!;
    final result = await ref.read(driversRepositoryProvider).updateDriver(
          id,
          driver.toJson()..['status'] = status.name,
        );

    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to update status.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(driver: result.data, clearError: true);
    ref.read(driverListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }

  Future<({String? error, bool suggestSuspend})> deleteDriver(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await ref.read(driversRepositoryProvider).deleteDriver(id);
    state = state.copyWith(isMutating: false);

    if (result.isSuccess) {
      ref.read(driverListRefreshSignalProvider.notifier).state++;
      return (error: null, suggestSuspend: false);
    }

    final failure = result.failure;
    return (
      error: failure?.message ?? 'Unable to delete driver.',
      suggestSuspend: failure?.statusCode == 409,
    );
  }

  Future<({String? error, int? statusCode})> suspendDriver(String id) async {
    return updateStatus(id, DriverStatus.SUSPENDED);
  }
}

final driverDetailProvider = AutoDisposeNotifierProviderFamily<
    DriverDetailNotifier, DriverDetailState, String>(
  DriverDetailNotifier.new,
);
