import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/vehicle.dart';
import '../domain/models/vehicle_status.dart';
import 'fleet_repository_provider.dart';

class VehicleFormState {
  const VehicleFormState({
    this.vehicle,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final Vehicle? vehicle;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  bool get isEditing => vehicle != null;

  VehicleFormState copyWith({
    Vehicle? vehicle,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return VehicleFormState(
      vehicle: vehicle ?? this.vehicle,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VehicleFormNotifier
    extends AutoDisposeFamilyNotifier<VehicleFormState, String?> {
  @override
  VehicleFormState build(String? vehicleId) {
    if (vehicleId != null) {
      Future.microtask(() => _load(vehicleId));
      return const VehicleFormState(isLoading: true);
    }
    return const VehicleFormState();
  }

  Future<void> _load(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await ref.read(fleetRepositoryProvider).fetchVehicle(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Vehicle not found.',
      );
      return;
    }

    state = state.copyWith(
      vehicle: result.data,
      isLoading: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> submit({
    required String registrationNumber,
    required String name,
    required String type,
    required double maxLoadCapacity,
    required double odometer,
    required String acquisitionCost,
    required VehicleStatus status,
    String? region,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final body = <String, dynamic>{
      'registrationNumber': registrationNumber.trim().toUpperCase(),
      'name': name.trim(),
      'type': type.trim(),
      'maxLoadCapacity': maxLoadCapacity,
      'odometer': odometer,
      'acquisitionCost': acquisitionCost.trim(),
      'status': status.name,
      'region': (region == null || region.trim().isEmpty) ? null : region.trim(),
    };

    final repository = ref.read(fleetRepositoryProvider);
    final vehicleId = arg;

    final result = vehicleId == null
        ? await repository.createVehicle(body)
        : await repository.updateVehicle(vehicleId, body);

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to save vehicle.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(fleetListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final vehicleFormProvider = AutoDisposeNotifierProviderFamily<
    VehicleFormNotifier, VehicleFormState, String?>(
  VehicleFormNotifier.new,
);
