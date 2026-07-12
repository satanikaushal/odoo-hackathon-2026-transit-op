import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/dashboard_filter_options.dart';
import '../domain/models/dashboard_kpis.dart';
import 'dashboard_repository_provider.dart';

class DashboardState {
  const DashboardState({
    this.filterOptions,
    this.kpis,
    this.selectedType,
    this.selectedStatus,
    this.selectedRegion,
    this.isInitialLoading = false,
    this.isKpisLoading = false,
    this.filtersError,
    this.kpisError,
  });

  static const _unset = Object();

  final DashboardFilterOptions? filterOptions;
  final DashboardKpis? kpis;
  final String? selectedType;
  final String? selectedStatus;
  final String? selectedRegion;
  final bool isInitialLoading;
  final bool isKpisLoading;
  final String? filtersError;
  final String? kpisError;

  DashboardState copyWith({
    DashboardFilterOptions? filterOptions,
    DashboardKpis? kpis,
    Object? selectedType = _unset,
    Object? selectedStatus = _unset,
    Object? selectedRegion = _unset,
    bool? isInitialLoading,
    bool? isKpisLoading,
    String? filtersError,
    String? kpisError,
    bool clearFiltersError = false,
    bool clearKpisError = false,
  }) {
    return DashboardState(
      filterOptions: filterOptions ?? this.filterOptions,
      kpis: kpis ?? this.kpis,
      selectedType:
          identical(selectedType, _unset) ? this.selectedType : selectedType as String?,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      selectedRegion: identical(selectedRegion, _unset)
          ? this.selectedRegion
          : selectedRegion as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isKpisLoading: isKpisLoading ?? this.isKpisLoading,
      filtersError:
          clearFiltersError ? null : (filtersError ?? this.filtersError),
      kpisError: clearKpisError ? null : (kpisError ?? this.kpisError),
    );
  }
}

class DashboardNotifier extends AutoDisposeNotifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(_loadInitial);
    return const DashboardState(isInitialLoading: true);
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearFiltersError: true,
      clearKpisError: true,
    );

    final repository = ref.read(dashboardRepositoryProvider);
    final filtersResult = await repository.fetchFilterOptions();

    if (filtersResult.isFailure || filtersResult.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        filtersError: filtersResult.failure?.message ??
            'Unable to load dashboard filters.',
      );
      return;
    }

    state = state.copyWith(
      filterOptions: filtersResult.data,
      isInitialLoading: false,
      clearFiltersError: true,
    );

    await _loadKpis();
  }

  Future<void> _loadKpis() async {
    state = state.copyWith(isKpisLoading: true, clearKpisError: true);

    final repository = ref.read(dashboardRepositoryProvider);
    final result = await repository.fetchKpis(
      type: state.selectedType,
      status: state.selectedStatus,
      region: state.selectedRegion,
    );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isKpisLoading: false,
        kpisError:
            result.failure?.message ?? 'Unable to load dashboard metrics.',
      );
      return;
    }

    state = state.copyWith(
      kpis: result.data,
      isKpisLoading: false,
      clearKpisError: true,
    );
  }

  Future<void> refresh() => _loadInitial();

  Future<void> retryKpis() => _loadKpis();

  void setType(String? value) {
    if (state.selectedType == value) {
      return;
    }
    state = state.copyWith(selectedType: value);
    _loadKpis();
  }

  void setStatus(String? value) {
    if (state.selectedStatus == value) {
      return;
    }
    state = state.copyWith(selectedStatus: value);
    _loadKpis();
  }

  void setRegion(String? value) {
    if (state.selectedRegion == value) {
      return;
    }
    state = state.copyWith(selectedRegion: value);
    _loadKpis();
  }
}

final dashboardProvider =
    AutoDisposeNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
