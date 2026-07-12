import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/maintenance_log.dart';
import 'maintenance_repository_provider.dart';

class MaintenanceDetailState {
  const MaintenanceDetailState({
    this.log,
    this.isLoading = false,
    this.error,
    this.isMutating = false,
  });

  final MaintenanceLog? log;
  final bool isLoading;
  final String? error;
  final bool isMutating;

  MaintenanceDetailState copyWith({
    MaintenanceLog? log,
    bool? isLoading,
    String? error,
    bool? isMutating,
    bool clearError = false,
  }) {
    return MaintenanceDetailState(
      log: log ?? this.log,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class MaintenanceDetailNotifier
    extends AutoDisposeFamilyNotifier<MaintenanceDetailState, String> {
  @override
  MaintenanceDetailState build(String id) {
    ref.listen<int>(maintenanceListRefreshSignalProvider, (_, next) {
      load(id);
    });

    Future.microtask(() => load(id));
    return const MaintenanceDetailState(isLoading: true);
  }

  Future<void> load(String id) async {
    if (state.log == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    final result =
        await ref.read(maintenanceRepositoryProvider).fetchLog(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Maintenance record not found.',
      );
      return;
    }

    state = state.copyWith(
      log: result.data,
      isLoading: false,
      clearError: true,
    );
  }

  Future<({String? error, int? statusCode})> closeLog(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result =
        await ref.read(maintenanceRepositoryProvider).closeLog(id);
    state = state.copyWith(isMutating: false);

    if (result.isFailure) {
      return (
        error: result.failure?.message ?? 'Unable to close maintenance record.',
        statusCode: result.failure?.statusCode,
      );
    }

    state = state.copyWith(log: result.data, clearError: true);
    ref.read(maintenanceListRefreshSignalProvider.notifier).state++;
    return (error: null, statusCode: null);
  }
}

final maintenanceDetailProvider = AutoDisposeNotifierProviderFamily<
    MaintenanceDetailNotifier, MaintenanceDetailState, String>(
  MaintenanceDetailNotifier.new,
);
