import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fleet/application/fleet_repository_provider.dart';
import '../../fleet/domain/models/vehicle.dart';
import '../../trips/application/trips_repository_provider.dart';
import '../../trips/domain/models/trip.dart';
import 'expenses_repository_provider.dart';

class FuelLogFormState {
  const FuelLogFormState({
    this.vehicles = const [],
    this.trips = const [],
    this.isLoadingOptions = false,
    this.isLoadingTrips = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<Vehicle> vehicles;
  final List<Trip> trips;
  final bool isLoadingOptions;
  final bool isLoadingTrips;
  final bool isSubmitting;
  final String? error;

  FuelLogFormState copyWith({
    List<Vehicle>? vehicles,
    List<Trip>? trips,
    bool? isLoadingOptions,
    bool? isLoadingTrips,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return FuelLogFormState(
      vehicles: vehicles ?? this.vehicles,
      trips: trips ?? this.trips,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FuelLogFormNotifier extends AutoDisposeNotifier<FuelLogFormState> {
  @override
  FuelLogFormState build() {
    Future.microtask(_loadVehicles);
    return const FuelLogFormState(isLoadingOptions: true);
  }

  Future<void> _loadVehicles() async {
    state = state.copyWith(isLoadingOptions: true, clearError: true);

    final result = await ref.read(fleetRepositoryProvider).fetchVehicles(
          page: 1,
          limit: 100,
        );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoadingOptions: false,
        error: result.failure?.message ?? 'Unable to load vehicles.',
      );
      return;
    }

    state = state.copyWith(
      vehicles: result.data!.items,
      isLoadingOptions: false,
      clearError: true,
    );
  }

  Future<void> loadTripsForVehicle(String vehicleId) async {
    state = state.copyWith(isLoadingTrips: true, trips: [], clearError: true);

    final result = await ref.read(tripsRepositoryProvider).fetchTrips(
          page: 1,
          limit: 100,
          vehicleId: vehicleId,
        );

    if (result.isFailure) {
      state = state.copyWith(
        isLoadingTrips: false,
        error: result.failure?.message ?? 'Unable to load trips.',
      );
      return;
    }

    state = state.copyWith(
      trips: result.data?.items ?? const [],
      isLoadingTrips: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> submit({
    required String vehicleId,
    required double liters,
    required String cost,
    String? tripId,
    DateTime? date,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final body = <String, dynamic>{
      'vehicleId': vehicleId,
      'liters': liters,
      'cost': cost.trim(),
    };
    if (tripId != null && tripId.isNotEmpty) {
      body['tripId'] = tripId;
    }
    if (date != null) {
      body['date'] = date.toUtc().toIso8601String();
    }

    final result =
        await ref.read(fuelLogsRepositoryProvider).createLog(body);

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to record fuel log.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(fuelLogListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final fuelLogFormProvider =
    AutoDisposeNotifierProvider<FuelLogFormNotifier, FuelLogFormState>(
  FuelLogFormNotifier.new,
);
