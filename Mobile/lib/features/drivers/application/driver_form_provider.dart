import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/driver.dart';
import '../domain/models/driver_status.dart';
import 'drivers_repository_provider.dart';

class DriverFormState {
  const DriverFormState({
    this.driver,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final Driver? driver;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  DriverFormState copyWith({
    Driver? driver,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return DriverFormState(
      driver: driver ?? this.driver,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DriverFormNotifier
    extends AutoDisposeFamilyNotifier<DriverFormState, String?> {
  @override
  DriverFormState build(String? driverId) {
    if (driverId != null) {
      Future.microtask(() => _load(driverId));
      return const DriverFormState(isLoading: true);
    }
    return const DriverFormState();
  }

  Future<void> _load(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
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

  Future<({String? error, int? statusCode})> submit({
    required String name,
    required String licenseNumber,
    required String licenseCategory,
    required DateTime licenseExpiryDate,
    required String contactNumber,
    required double safetyScore,
    required DriverStatus status,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final body = {
      'name': name.trim(),
      'licenseNumber': licenseNumber.trim(),
      'licenseCategory': licenseCategory.trim(),
      'licenseExpiryDate': Driver.formatDateForApi(licenseExpiryDate),
      'contactNumber': contactNumber.trim(),
      'safetyScore': safetyScore,
      'status': status.name,
    };

    final repository = ref.read(driversRepositoryProvider);
    final driverId = arg;

    final result = driverId == null
        ? await repository.createDriver(body)
        : await repository.updateDriver(driverId, body);

    state = state.copyWith(isSubmitting: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to save driver.',
        statusCode: result.failure?.statusCode,
      );
    }

    ref.read(driverListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final driverFormProvider = AutoDisposeNotifierProviderFamily<
    DriverFormNotifier, DriverFormState, String?>(
  DriverFormNotifier.new,
);
