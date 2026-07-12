import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/trip.dart';
import 'trips_repository_provider.dart';

class TripDetailState {
  const TripDetailState({
    this.trip,
    this.isLoading = false,
    this.error,
    this.isMutating = false,
  });

  final Trip? trip;
  final bool isLoading;
  final String? error;
  final bool isMutating;

  TripDetailState copyWith({
    Trip? trip,
    bool? isLoading,
    String? error,
    bool? isMutating,
    bool clearError = false,
  }) {
    return TripDetailState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class TripDetailNotifier
    extends AutoDisposeFamilyNotifier<TripDetailState, String> {
  @override
  TripDetailState build(String id) {
    ref.listen<int>(tripListRefreshSignalProvider, (_, next) {
      load(id);
    });

    Future.microtask(() => load(id));
    return const TripDetailState(isLoading: true);
  }

  Future<void> load(String id) async {
    if (state.trip == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    final result = await ref.read(tripsRepositoryProvider).fetchTrip(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Trip not found.',
      );
      return;
    }

    state = state.copyWith(
      trip: result.data,
      isLoading: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> dispatch(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await ref.read(tripsRepositoryProvider).dispatchTrip(id);
    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to dispatch trip.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(trip: result.data, clearError: true);
    ref.read(tripListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }

  Future<({String? error, int? statusCode})> cancel(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await ref.read(tripsRepositoryProvider).cancelTrip(id);
    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to cancel trip.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(trip: result.data, clearError: true);
    ref.read(tripListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }

  Future<({String? error, int? statusCode})> complete(
    String id, {
    required double finalOdometer,
    double? fuelConsumed,
    String? revenue,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    final body = <String, dynamic>{
      'finalOdometer': finalOdometer,
    };
    if (fuelConsumed != null) {
      body['fuelConsumed'] = fuelConsumed;
    }
    if (revenue != null && revenue.isNotEmpty) {
      body['revenue'] = revenue;
    }

    final result =
        await ref.read(tripsRepositoryProvider).completeTrip(id, body);
    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to complete trip.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(trip: result.data, clearError: true);
    ref.read(tripListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final tripDetailProvider = AutoDisposeNotifierProviderFamily<
    TripDetailNotifier, TripDetailState, String>(
  TripDetailNotifier.new,
);
