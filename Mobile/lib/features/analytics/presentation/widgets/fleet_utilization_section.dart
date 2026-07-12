import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/analytics_formatters.dart';
import '../../domain/models/fleet_utilization_report.dart';

class FleetUtilizationSection extends StatelessWidget {
  const FleetUtilizationSection({
    super.key,
    required this.report,
  });

  final FleetUtilizationReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiTile(
            label: 'Utilization',
            value: AnalyticsFormatters.formatPercent(report.utilizationPct),
            highlight: true,
          ),
          const AppGap(12),
          _KpiTile(
            label: 'On Trip',
            value: report.onTripVehicles.toString(),
          ),
          const AppGap(8),
          _KpiTile(
            label: 'Non-Retired Fleet',
            value: report.nonRetiredVehicles.toString(),
          ),
          const AppGap(8),
          _KpiTile(
            label: 'Total Vehicles',
            value: report.totalVehicles.toString(),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            size: highlight ? 14 : 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        AppText(
          value,
          size: highlight ? 22 : 15,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}
