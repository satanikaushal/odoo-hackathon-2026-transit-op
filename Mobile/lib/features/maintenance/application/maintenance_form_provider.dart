import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fleet/application/fleet_repository_provider.dart';
import '../../fleet/domain/models/vehicle.dart';
import '../../fleet/domain/models/vehicle_status.dart';
import 'maintenance_repository_provider.dart';

class MaintenanceFormState {
  const MaintenanceFormState({
    this.vehicles = const [],
    this.isLoadingOptions = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<Vehicle> vehicles;
  final bool isLoadingOptions;
  final bool isSubmitting;
  final String? error;

  MaintenanceFormState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoadingOptions,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return MaintenanceFormState(
      vehicles: vehicles ?? this.vehicles,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MaintenanceFormNotifier extends AutoDisposeNotifier<MaintenanceFormState> {
  @override
  MaintenanceFormState build() {
    Future.microtask(_loadOptions);
    return const MaintenanceFormState(isLoadingOptions: true);
  }

  Future<void> _loadOptions() async {
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

    final eligible = result.data!.items
        .where(
          (vehicle) =>
              vehicle.status != VehicleStatus.ON_TRIP &&
              vehicle.status != VehicleStatus.RETIRED,
        )
        .toList();

    state = state.copyWith(
      vehicles: eligible,
      isLoadingOptions: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> submit({
    required String vehicleId,
    required String description,
    String? cost,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final body = <String, dynamic>{
      'vehicleId': vehicleId,
      'description': description.trim(),
    };
    if (cost != null && cost.trim().isNotEmpty) {
      body['cost'] = cost.trim();
    }

    final result =
        await ref.read(maintenanceRepositoryProvider).openLog(body);

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to open maintenance record.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(maintenanceListRefreshSignalProvider.notifier).state++;
    ref.read(fleetListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final maintenanceFormProvider =
    AutoDisposeNotifierProvider<MaintenanceFormNotifier, MaintenanceFormState>(
  MaintenanceFormNotifier.new,
);
