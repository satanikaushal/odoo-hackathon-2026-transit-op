import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/vehicle.dart';
import 'fleet_repository_provider.dart';

class FleetListState {
  const FleetListState({
    this.vehicles = const [],
    this.typeOptions = const [],
    this.selectedType,
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

  final List<Vehicle> vehicles;
  final List<String> typeOptions;
  final String? selectedType;
  final String? selectedStatus;
  final String searchQuery;
  final bool isInitialLoading;
  final bool isRefreshingList;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  FleetListState copyWith({
    List<Vehicle>? vehicles,
    List<String>? typeOptions,
    Object? selectedType = _unset,
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
    return FleetListState(
      vehicles: vehicles ?? this.vehicles,
      typeOptions: typeOptions ?? this.typeOptions,
      selectedType: identical(selectedType, _unset)
          ? this.selectedType
          : selectedType as String?,
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

class FleetListNotifier extends AutoDisposeNotifier<FleetListState> {
  Timer? _searchDebounce;

  @override
  FleetListState build() {
    ref.listen<int>(fleetListRefreshSignalProvider, (_, next) {
      refresh();
    });

    Future.microtask(_loadInitial);
    ref.onDispose(() => _searchDebounce?.cancel());
    return const FleetListState(isInitialLoading: true);
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      vehicles: [],
      currentPage: 0,
      hasMore: true,
    );

    final repository = ref.read(fleetRepositoryProvider);
    final filtersResult = await repository.fetchFilterOptions();

    if (filtersResult.isSuccess && filtersResult.data != null) {
      state = state.copyWith(typeOptions: filtersResult.data!.types);
    }

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
    } else if (state.vehicles.isEmpty && state.typeOptions.isEmpty) {
      state = state.copyWith(isInitialLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshingList: true, clearError: true);
    }

    final repository = ref.read(fleetRepositoryProvider);
    final result = await repository.fetchVehicles(
      page: page,
      status: state.selectedStatus,
      type: state.selectedType,
      search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
    );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshingList: false,
        isLoadingMore: false,
        error: result.failure?.message ?? 'Unable to load vehicles.',
      );
      return;
    }

    final data = result.data!;
    final merged = append ? [...state.vehicles, ...data.items] : data.items;

    state = state.copyWith(
      vehicles: merged,
      isInitialLoading: false,
      isRefreshingList: false,
      isLoadingMore: false,
      hasMore: data.pagination.hasNextPage,
      currentPage: data.pagination.page,
      clearError: true,
    );
  }

  void setType(String? value) {
    if (state.selectedType == value) {
      return;
    }
    state = state.copyWith(selectedType: value);
    _reloadFromFirstPage();
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

final fleetListProvider =
    AutoDisposeNotifierProvider<FleetListNotifier, FleetListState>(
  FleetListNotifier.new,
);
