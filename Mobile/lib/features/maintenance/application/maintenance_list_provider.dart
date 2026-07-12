import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/maintenance_log.dart';
import 'maintenance_repository_provider.dart';

class MaintenanceListState {
  const MaintenanceListState({
    this.logs = const [],
    this.selectedStatus,
    this.isInitialLoading = false,
    this.isRefreshingList = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  static const _unset = Object();

  final List<MaintenanceLog> logs;
  final String? selectedStatus;
  final bool isInitialLoading;
  final bool isRefreshingList;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  MaintenanceListState copyWith({
    List<MaintenanceLog>? logs,
    Object? selectedStatus = _unset,
    bool? isInitialLoading,
    bool? isRefreshingList,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool clearError = false,
  }) {
    return MaintenanceListState(
      logs: logs ?? this.logs,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class MaintenanceListNotifier extends AutoDisposeNotifier<MaintenanceListState> {
  @override
  MaintenanceListState build() {
    ref.listen<int>(maintenanceListRefreshSignalProvider, (_, next) {
      refresh();
    });

    Future.microtask(_loadInitial);
    return const MaintenanceListState(isInitialLoading: true);
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

    final result = await ref.read(maintenanceRepositoryProvider).fetchLogs(
          page: page,
          status: state.selectedStatus,
        );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshingList: false,
        isLoadingMore: false,
        error: result.failure?.message ?? 'Unable to load maintenance logs.',
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

  void setStatus(String? value) {
    if (state.selectedStatus == value) {
      return;
    }
    state = state.copyWith(selectedStatus: value);
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

final maintenanceListProvider =
    AutoDisposeNotifierProvider<MaintenanceListNotifier, MaintenanceListState>(
  MaintenanceListNotifier.new,
);
