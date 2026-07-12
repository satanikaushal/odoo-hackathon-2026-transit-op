import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expenses/application/expenses_repository_provider.dart';
import '../../maintenance/application/maintenance_repository_provider.dart';
import '../domain/models/vehicle.dart';
import '../domain/models/vehicle_operational_cost.dart';
import '../domain/models/vehicle_status.dart';
import 'fleet_repository_provider.dart';

class VehicleDetailState {
  const VehicleDetailState({
    this.vehicle,
    this.operationalCost,
    this.isLoading = false,
    this.isCostsLoading = false,
    this.error,
    this.costsError,
    this.isMutating = false,
  });

  final Vehicle? vehicle;
  final VehicleOperationalCost? operationalCost;
  final bool isLoading;
  final bool isCostsLoading;
  final String? error;
  final String? costsError;
  final bool isMutating;

  VehicleDetailState copyWith({
    Vehicle? vehicle,
    VehicleOperationalCost? operationalCost,
    bool? isLoading,
    bool? isCostsLoading,
    String? error,
    String? costsError,
    bool? isMutating,
    bool clearError = false,
    bool clearCostsError = false,
  }) {
    return VehicleDetailState(
      vehicle: vehicle ?? this.vehicle,
      operationalCost: operationalCost ?? this.operationalCost,
      isLoading: isLoading ?? this.isLoading,
      isCostsLoading: isCostsLoading ?? this.isCostsLoading,
      error: clearError ? null : (error ?? this.error),
      costsError: clearCostsError ? null : (costsError ?? this.costsError),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class VehicleDetailNotifier extends AutoDisposeFamilyNotifier<
    VehicleDetailState, String> {
  @override
  VehicleDetailState build(String id) {
    ref.listen<int>(fleetListRefreshSignalProvider, (_, next) {
      load(id);
    });
    ref.listen<int>(fuelLogListRefreshSignalProvider, (_, next) {
      loadCosts(id);
    });
    ref.listen<int>(maintenanceListRefreshSignalProvider, (_, next) {
      loadCosts(id);
    });

    Future.microtask(() => load(id));
    return const VehicleDetailState(isLoading: true, isCostsLoading: true);
  }

  Future<void> load(String id) async {
    if (state.vehicle == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    final result = await ref.read(fleetRepositoryProvider).fetchVehicle(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        isCostsLoading: false,
        error: result.failure?.message ?? 'Vehicle not found.',
      );
      return;
    }

    state = state.copyWith(
      vehicle: result.data,
      isLoading: false,
      clearError: true,
    );

    await loadCosts(id);
  }

  Future<void> loadCosts(String id) async {
    if (state.operationalCost == null) {
      state = state.copyWith(isCostsLoading: true, clearCostsError: true);
    } else {
      state = state.copyWith(clearCostsError: true);
    }

    final result =
        await ref.read(fleetRepositoryProvider).fetchVehicleCosts(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isCostsLoading: false,
        costsError:
            result.failure?.message ?? 'Unable to load operational cost.',
      );
      return;
    }

    state = state.copyWith(
      operationalCost: result.data,
      isCostsLoading: false,
      clearCostsError: true,
    );
  }

  Future<({String? error, int? statusCode})> updateStatus(
    String id,
    VehicleStatus status,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result =
        await ref.read(fleetRepositoryProvider).updateVehicleStatus(id, status);

    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to update status.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(vehicle: result.data, clearError: true);
    ref.read(fleetListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }

  Future<({String? error, bool suggestRetire})> deleteVehicle(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await ref.read(fleetRepositoryProvider).deleteVehicle(id);
    state = state.copyWith(isMutating: false);

    if (result.isSuccess) {
      ref.read(fleetListRefreshSignalProvider.notifier).state++;
      return (error: null, suggestRetire: false);
    }

    final failure = result.failure;
    final suggestRetire = failure?.statusCode == 409;
    return (
      error: failure?.message ?? 'Unable to delete vehicle.',
      suggestRetire: suggestRetire,
    );
  }

  Future<({String? error, int? statusCode})> retireVehicle(String id) async {
    return updateStatus(id, VehicleStatus.RETIRED);
  }
}

final vehicleDetailProvider = AutoDisposeNotifierProviderFamily<
    VehicleDetailNotifier, VehicleDetailState, String>(
  VehicleDetailNotifier.new,
);
