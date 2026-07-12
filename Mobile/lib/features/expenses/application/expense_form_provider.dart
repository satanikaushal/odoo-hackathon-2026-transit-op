import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fleet/application/fleet_repository_provider.dart';
import '../../fleet/domain/models/vehicle.dart';
import '../../trips/application/trips_repository_provider.dart';
import '../../trips/domain/models/trip.dart';
import '../domain/models/expense_category.dart';
import 'expenses_repository_provider.dart';

class ExpenseFormState {
  const ExpenseFormState({
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

  ExpenseFormState copyWith({
    List<Vehicle>? vehicles,
    List<Trip>? trips,
    bool? isLoadingOptions,
    bool? isLoadingTrips,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ExpenseFormState(
      vehicles: vehicles ?? this.vehicles,
      trips: trips ?? this.trips,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpenseFormNotifier extends AutoDisposeNotifier<ExpenseFormState> {
  @override
  ExpenseFormState build() {
    Future.microtask(_loadVehicles);
    return const ExpenseFormState(isLoadingOptions: true);
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
    required ExpenseCategory category,
    required String amount,
    String? tripId,
    String? description,
    DateTime? date,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final body = <String, dynamic>{
      'vehicleId': vehicleId,
      'category': category.apiValue,
      'amount': amount.trim(),
    };
    if (tripId != null && tripId.isNotEmpty) {
      body['tripId'] = tripId;
    }
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (date != null) {
      body['date'] = date.toUtc().toIso8601String();
    }

    final result =
        await ref.read(expensesRepositoryProvider).createExpense(body);

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to record expense.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(expenseListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final expenseFormProvider =
    AutoDisposeNotifierProvider<ExpenseFormNotifier, ExpenseFormState>(
  ExpenseFormNotifier.new,
);
