import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/shell_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/analytics_provider.dart';
import '../../domain/csv_export_helper.dart';
import '../../domain/models/report_type.dart';
import '../widgets/analytics_shimmer.dart';
import '../widgets/fleet_utilization_section.dart';
import '../widgets/report_data_views.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final notifier = ref.read(analyticsProvider.notifier);
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        _ReportSelector(
          selected: state.selectedReport,
          onChanged: notifier.selectReport,
        ),
        const AppGap(12),
        Align(
          alignment: Alignment.centerRight,
          child: Builder(
            builder: (buttonContext) => AppButton(
              label: 'Export CSV',
              expand: false,
              isLoading: state.isExporting,
              onPressed: state.isExporting
                  ? null
                  : () => _export(
                        buttonContext,
                        ref,
                        state.selectedReport,
                      ),
            ),
          ),
        ),
        const AppGap(16),
        if (state.isLoading && state.isEmptyForSelected)
          const AnalyticsReportShimmer()
        else if (state.error != null && state.isEmptyForSelected)
          _AnalyticsErrorView(
            message: state.error!,
            onRetry: notifier.refresh,
          )
        else ...[
          if (state.isLoading) const AnalyticsReportItemsShimmer(),
          if (!state.isLoading) _ReportBody(state: state, useTable: useTable),
        ],
        const AppGap(12),
        const AppGap(16),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReportType report,
  ) async {
    final result = await ref.read(analyticsProvider.notifier).exportSelected();
    if (!context.mounted) {
      return;
    }

    if (result.error != null) {
      showSnackBarMessage(context, result.error!);
      return;
    }

    final outcome = await CsvExportHelper.exportReportCsv(
      report: report,
      csv: result.csv!,
      sharePositionOrigin: _shareOrigin(context),
    );

    if (!context.mounted) {
      return;
    }

    switch (outcome) {
      case CsvExportOutcome.saved:
        showSnackBarMessage(
          context,
          'CSV ready — use Save to Files from the share menu.',
        );
      case CsvExportOutcome.cancelled:
        break;
      case CsvExportOutcome.failed:
        showSnackBarMessage(context, 'Unable to export CSV file.');
    }
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return null;
    }

    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }
}

class _ReportSelector extends StatelessWidget {
  const _ReportSelector({
    required this.selected,
    required this.onChanged,
  });

  final ReportType selected;
  final ValueChanged<ReportType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Report',
        contentPadding: Responsive.getPaddingSymmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportType>(
          isExpanded: true,
          value: selected,
          items: ReportType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          style: TextStyle(
            fontSize: Responsive.getF(14),
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.state,
    required this.useTable,
  });

  final AnalyticsState state;
  final bool useTable;

  @override
  Widget build(BuildContext context) {
    return switch (state.selectedReport) {
      ReportType.fuelEfficiency => _buildListOrEmpty(
          context,
          state.fuelEfficiency.isEmpty,
          useTable
              ? FuelEfficiencyTable(rows: state.fuelEfficiency)
              : FuelEfficiencyList(rows: state.fuelEfficiency),
        ),
      ReportType.fleetUtilization => state.fleetUtilization == null
          ? const _AnalyticsEmptyView()
          : FleetUtilizationSection(report: state.fleetUtilization!),
      ReportType.operationalCost => _buildListOrEmpty(
          context,
          state.operationalCost.isEmpty,
          useTable
              ? OperationalCostTable(rows: state.operationalCost)
              : OperationalCostList(rows: state.operationalCost),
        ),
      ReportType.vehicleRoi => _buildListOrEmpty(
          context,
          state.vehicleRoi.isEmpty,
          useTable
              ? VehicleRoiTable(rows: state.vehicleRoi)
              : VehicleRoiList(rows: state.vehicleRoi),
        ),
    };
  }

  Widget _buildListOrEmpty(
    BuildContext context,
    bool isEmpty,
    Widget content,
  ) {
    if (isEmpty) {
      return const _AnalyticsEmptyView();
    }
    return content;
  }
}

class _AnalyticsEmptyView extends StatelessWidget {
  const _AnalyticsEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          'No data for this report',
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AnalyticsErrorView extends StatelessWidget {
  const _AnalyticsErrorView({
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
      width: double.infinity,
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
