import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/fuel_log.dart';
import 'expenses_repository_provider.dart';

class FuelLogListState {
  const FuelLogListState({
    this.logs = const [],
    this.selectedVehicleId,
    this.isInitialLoading = false,
    this.isRefreshingList = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  static const _unset = Object();

  final List<FuelLog> logs;
  final String? selectedVehicleId;
  final bool isInitialLoading;
  final bool isRefreshingList;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  FuelLogListState copyWith({
    List<FuelLog>? logs,
    Object? selectedVehicleId = _unset,
    bool? isInitialLoading,
    bool? isRefreshingList,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool clearError = false,
  }) {
    return FuelLogListState(
      logs: logs ?? this.logs,
      selectedVehicleId: identical(selectedVehicleId, _unset)
          ? this.selectedVehicleId
          : selectedVehicleId as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FuelLogListNotifier extends AutoDisposeNotifier<FuelLogListState> {
  @override
  FuelLogListState build() {
    ref.listen<int>(fuelLogListRefreshSignalProvider, (_, next) {
      refresh();
    });

    Future.microtask(_loadInitial);
    return const FuelLogListState(isInitialLoading: true);
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      logs: [],
      currentPage: 0,
      hasMore: true,
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshingList ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.error != null) {
      return;
    }
    await _fetchPage(page: state.currentPage + 1, append: true);
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else if (state.logs.isEmpty) {
      state = state.copyWith(isInitialLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshingList: true, clearError: true);
    }

    final result = await ref.read(fuelLogsRepositoryProvider).fetchLogs(
          page: page,
          vehicleId: state.selectedVehicleId,
        );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshingList: false,
        isLoadingMore: false,
        error: result.failure?.message ?? 'Unable to load fuel logs.',
      );
      return;
    }

    final data = result.data!;
    final merged = append ? [...state.logs, ...data.items] : data.items;

    state = state.copyWith(
      logs: merged,
      isInitialLoading: false,
      isRefreshingList: false,
      isLoadingMore: false,
      hasMore: data.pagination.hasNextPage,
      currentPage: data.pagination.page,
      clearError: true,
    );
  }

  void setVehicle(String? vehicleId) {
    if (state.selectedVehicleId == vehicleId) {
      return;
    }
    state = state.copyWith(selectedVehicleId: vehicleId);
    _reloadFromFirstPage();
  }

  Future<void> _reloadFromFirstPage() async {
    state = state.copyWith(
      currentPage: 0,
      hasMore: true,
      clearError: true,
    );
    await _fetchPage(page: 1, append: false);
  }
}

final fuelLogListProvider =
    AutoDisposeNotifierProvider<FuelLogListNotifier, FuelLogListState>(
  FuelLogListNotifier.new,
);
