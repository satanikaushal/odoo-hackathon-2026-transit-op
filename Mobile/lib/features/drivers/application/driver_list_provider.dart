import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/driver.dart';
import 'drivers_repository_provider.dart';

class DriverListState {
  const DriverListState({
    this.drivers = const [],
    this.selectedStatus,
    this.searchQuery = '',
    this.isInitialLoading = false,
    this.isRefreshingList = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  static const _unset = Object();

  final List<Driver> drivers;
  final String? selectedStatus;
  final String searchQuery;
  final bool isInitialLoading;
  final bool isRefreshingList;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  DriverListState copyWith({
    List<Driver>? drivers,
    Object? selectedStatus = _unset,
    String? searchQuery,
    bool? isInitialLoading,
    bool? isRefreshingList,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool clearError = false,
  }) {
    return DriverListState(
      drivers: drivers ?? this.drivers,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class DriverListNotifier extends AutoDisposeNotifier<DriverListState> {
  Timer? _searchDebounce;

  @override
  DriverListState build() {
    ref.listen<int>(driverListRefreshSignalProvider, (_, next) {
      refresh();
    });

    Future.microtask(_loadInitial);
    ref.onDispose(() => _searchDebounce?.cancel());
    return const DriverListState(isInitialLoading: true);
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      drivers: [],
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
    } else if (state.drivers.isEmpty) {
      state = state.copyWith(isInitialLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshingList: true, clearError: true);
    }

    final result = await ref.read(driversRepositoryProvider).fetchDrivers(
          page: page,
          status: state.selectedStatus,
          query: state.searchQuery.trim().isEmpty
              ? null
              : state.searchQuery.trim(),
        );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshingList: false,
        isLoadingMore: false,
        error: result.failure?.message ?? 'Unable to load drivers.',
      );
      return;
    }

    final data = result.data!;
    final merged = append ? [...state.drivers, ...data.items] : data.items;

    state = state.copyWith(
      drivers: merged,
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

  void setSearchQuery(String value) {
    if (state.searchQuery == value) {
      return;
    }
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _reloadFromFirstPage();
    });
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

final driverListProvider =
    AutoDisposeNotifierProvider<DriverListNotifier, DriverListState>(
  DriverListNotifier.new,
);
