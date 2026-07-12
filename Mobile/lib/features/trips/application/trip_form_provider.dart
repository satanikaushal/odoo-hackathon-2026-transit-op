import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../drivers/application/drivers_repository_provider.dart';
import '../../fleet/application/fleet_repository_provider.dart';
import '../../fleet/domain/models/vehicle.dart';
import '../../drivers/domain/models/driver.dart';
import 'trips_repository_provider.dart';

class TripFormState {
  const TripFormState({
    this.vehicles = const [],
    this.drivers = const [],
    this.isLoadingOptions = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<Vehicle> vehicles;
  final List<Driver> drivers;
  final bool isLoadingOptions;
  final bool isSubmitting;
  final String? error;

  TripFormState copyWith({
    List<Vehicle>? vehicles,
    List<Driver>? drivers,
    bool? isLoadingOptions,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return TripFormState(
      vehicles: vehicles ?? this.vehicles,
      drivers: drivers ?? this.drivers,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripFormNotifier extends AutoDisposeNotifier<TripFormState> {
  @override
  TripFormState build() {
    Future.microtask(_loadOptions);
    return const TripFormState(isLoadingOptions: true);
  }

  Future<void> _loadOptions() async {
    state = state.copyWith(isLoadingOptions: true, clearError: true);

    final fleetRepo = ref.read(fleetRepositoryProvider);
    final driversRepo = ref.read(driversRepositoryProvider);

    final vehiclesResult = await fleetRepo.fetchVehicles(
      page: 1,
      limit: 100,
      status: 'AVAILABLE',
    );
    final driversResult = await driversRepo.fetchDrivers(
      page: 1,
      limit: 100,
      status: 'AVAILABLE',
    );

    if (vehiclesResult.isFailure && driversResult.isFailure) {
      state = state.copyWith(
        isLoadingOptions: false,
        error: 'Unable to load vehicles and drivers.',
      );
      return;
    }

    state = state.copyWith(
      vehicles: vehiclesResult.data?.items ?? const [],
      drivers: driversResult.data?.items ?? const [],
      isLoadingOptions: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> submit({
    required String source,
    required String destination,
    required String vehicleId,
    required String driverId,
    required double cargoWeight,
    required double plannedDistance,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref.read(tripsRepositoryProvider).createTrip({
      'source': source.trim(),
      'destination': destination.trim(),
      'vehicleId': vehicleId,
      'driverId': driverId,
      'cargoWeight': cargoWeight,
      'plannedDistance': plannedDistance,
    });

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to create trip.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(tripListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final tripFormProvider =
    AutoDisposeNotifierProvider<TripFormNotifier, TripFormState>(
  TripFormNotifier.new,
);
