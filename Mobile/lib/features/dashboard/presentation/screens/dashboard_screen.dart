import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/dashboard_provider.dart';
import '../../domain/models/dashboard_kpis.dart';
import '../widgets/dashboard_filters_section.dart';
import '../widgets/dashboard_loading_shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        if (state.isInitialLoading)
          const DashboardLoadingShimmer()
        else if (state.filtersError != null)
          _DashboardErrorCard(
            message: state.filtersError!,
            onRetry: notifier.refresh,
          )
        else if (state.filterOptions != null) ...[
          DashboardFiltersSection(
            options: state.filterOptions!,
            selectedType: state.selectedType,
            selectedStatus: state.selectedStatus,
            selectedRegion: state.selectedRegion,
            onTypeChanged: notifier.setType,
            onStatusChanged: notifier.setStatus,
            onRegionChanged: notifier.setRegion,
          ),
          const AppGap(20),
          _DashboardKpiSection(
            kpis: state.kpis,
            isLoading: state.isKpisLoading,
            error: state.kpisError,
            onRetry: notifier.retryKpis,
          ),
        ],
        const AppGap(16),
      ],
    );
  }
}

class _DashboardKpiSection extends StatelessWidget {
  const _DashboardKpiSection({
    required this.kpis,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final DashboardKpis? kpis;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final kpiItems = kpis == null ? null : _buildKpiItems(kpis!);

    if (error != null && kpis == null) {
      return _DashboardErrorCard(
        message: error!,
        onRetry: onRetry,
      );
    }

    if (isLoading && kpis == null) {
      return const DashboardKpiLoadingShimmer();
    }

    if (kpiItems == null) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return const DashboardKpiLoadingShimmer();
    }

    return DashboardKpiList(items: kpiItems);
  }

  List<({String label, String value, Color accent})> _buildKpiItems(
    DashboardKpis kpis,
  ) {
    return [
      (
        label: 'Active Vehicles',
        value: kpis.activeVehicles.toString().padLeft(2, '0'),
        accent: AppColors.info,
      ),
      (
        label: 'Available Vehicles',
        value: kpis.availableVehicles.toString().padLeft(2, '0'),
        accent: AppColors.success,
      ),
      (
        label: 'In Maintenance',
        value: kpis.vehiclesInMaintenance.toString().padLeft(2, '0'),
        accent: AppColors.warning,
      ),
      (
        label: 'Active Trips',
        value: kpis.activeTrips.toString().padLeft(2, '0'),
        accent: AppColors.info,
      ),
      (
        label: 'Pending Trips',
        value: kpis.pendingTrips.toString().padLeft(2, '0'),
        accent: AppColors.draft,
      ),
      (
        label: 'Drivers on Duty',
        value: kpis.driversOnDuty.toString().padLeft(2, '0'),
        accent: AppColors.info,
      ),
      (
        label: 'Fleet Utilization',
        value: '${kpis.fleetUtilization.round()}%',
        accent: AppColors.success,
      ),
    ];
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          AppText(
            message,
            size: 14,
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const AppGap(16),
          AppButton(
            label: 'Retry',
            onPressed: onRetry,
            expand: false,
          ),
        ],
      ),
    );
  }
}
