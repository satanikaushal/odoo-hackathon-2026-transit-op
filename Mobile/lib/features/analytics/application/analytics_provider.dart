import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/fleet_utilization_report.dart';
import '../domain/models/fuel_efficiency_row.dart';
import '../domain/models/operational_cost_row.dart';
import '../domain/models/report_type.dart';
import '../domain/models/vehicle_roi_row.dart';
import 'reports_repository_provider.dart';

class AnalyticsState {
  const AnalyticsState({
    this.selectedReport = ReportType.fuelEfficiency,
    this.isLoading = false,
    this.isExporting = false,
    this.error,
    this.fuelEfficiency = const [],
    this.fleetUtilization,
    this.operationalCost = const [],
    this.vehicleRoi = const [],
  });

  final ReportType selectedReport;
  final bool isLoading;
  final bool isExporting;
  final String? error;
  final List<FuelEfficiencyRow> fuelEfficiency;
  final FleetUtilizationReport? fleetUtilization;
  final List<OperationalCostRow> operationalCost;
  final List<VehicleRoiRow> vehicleRoi;

  AnalyticsState copyWith({
    ReportType? selectedReport,
    bool? isLoading,
    bool? isExporting,
    String? error,
    List<FuelEfficiencyRow>? fuelEfficiency,
    FleetUtilizationReport? fleetUtilization,
    List<OperationalCostRow>? operationalCost,
    List<VehicleRoiRow>? vehicleRoi,
    bool clearError = false,
    bool clearFleetUtilization = false,
  }) {
    return AnalyticsState(
      selectedReport: selectedReport ?? this.selectedReport,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      fleetUtilization: clearFleetUtilization
          ? null
          : (fleetUtilization ?? this.fleetUtilization),
      operationalCost: operationalCost ?? this.operationalCost,
      vehicleRoi: vehicleRoi ?? this.vehicleRoi,
    );
  }

  bool get isEmptyForSelected {
    return switch (selectedReport) {
      ReportType.fuelEfficiency => fuelEfficiency.isEmpty,
      ReportType.fleetUtilization => fleetUtilization == null,
      ReportType.operationalCost => operationalCost.isEmpty,
      ReportType.vehicleRoi => vehicleRoi.isEmpty,
    };
  }
}

class AnalyticsNotifier extends AutoDisposeNotifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    ref.listen<int>(analyticsRefreshSignalProvider, (_, next) {
      _loadSelected(force: true);
    });

    Future.microtask(() => _loadSelected(force: true));
    return const AnalyticsState(isLoading: true);
  }

  void selectReport(ReportType report) {
    if (state.selectedReport == report) {
      return;
    }
    state = state.copyWith(selectedReport: report, clearError: true);
    _loadSelected(force: false);
  }

  Future<void> refresh() => _loadSelected(force: true);

  Future<void> _loadSelected({required bool force}) async {
    final report = state.selectedReport;
    if (!force && _hasCachedData(report)) {
      return;
    }

    final hasData = _hasCachedData(report);
    state = state.copyWith(
      isLoading: !hasData,
      clearError: true,
    );

    final repository = ref.read(reportsRepositoryProvider);

    switch (report) {
      case ReportType.fuelEfficiency:
        final result = await repository.fetchFuelEfficiency();
        if (result.isFailure) {
          state = state.copyWith(
            isLoading: false,
            error: result.failure?.message ?? 'Unable to load report.',
          );
          return;
        }
        state = state.copyWith(
          fuelEfficiency: result.data ?? const [],
          isLoading: false,
          clearError: true,
        );
      case ReportType.fleetUtilization:
        final result = await repository.fetchFleetUtilization();
        if (result.isFailure) {
          state = state.copyWith(
            isLoading: false,
            error: result.failure?.message ?? 'Unable to load report.',
          );
          return;
        }
        state = state.copyWith(
          fleetUtilization: result.data,
          isLoading: false,
          clearError: true,
        );
      case ReportType.operationalCost:
        final result = await repository.fetchOperationalCost();
        if (result.isFailure) {
          state = state.copyWith(
            isLoading: false,
            error: result.failure?.message ?? 'Unable to load report.',
          );
          return;
        }
        state = state.copyWith(
          operationalCost: result.data ?? const [],
          isLoading: false,
          clearError: true,
        );
      case ReportType.vehicleRoi:
        final result = await repository.fetchVehicleRoi();
        if (result.isFailure) {
          state = state.copyWith(
            isLoading: false,
            error: result.failure?.message ?? 'Unable to load report.',
          );
          return;
        }
        state = state.copyWith(
          vehicleRoi: result.data ?? const [],
          isLoading: false,
          clearError: true,
        );
    }
  }

  bool _hasCachedData(ReportType report) {
    return switch (report) {
      ReportType.fuelEfficiency => state.fuelEfficiency.isNotEmpty,
      ReportType.fleetUtilization => state.fleetUtilization != null,
      ReportType.operationalCost => state.operationalCost.isNotEmpty,
      ReportType.vehicleRoi => state.vehicleRoi.isNotEmpty,
    };
  }

  Future<({String? error, String? csv})> exportSelected() async {
    state = state.copyWith(isExporting: true, clearError: true);
    final result = await ref
        .read(reportsRepositoryProvider)
        .exportCsv(state.selectedReport);
    state = state.copyWith(isExporting: false);

    if (result.isFailure) {
      return (error: result.failure?.message ?? 'Export failed.', csv: null);
    }

    return (error: null, csv: result.data);
  }
}

final analyticsProvider =
    AutoDisposeNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  AnalyticsNotifier.new,
);
