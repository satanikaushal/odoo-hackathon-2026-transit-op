import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/vehicle_status_breakdown.dart';

class DashboardVehicleStatusChart extends StatelessWidget {
  const DashboardVehicleStatusChart({
    super.key,
    required this.breakdown,
  });

  final VehicleStatusBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final trackColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final total = breakdown.total == 0 ? 1 : breakdown.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Vehicle Status',
          size: 16,
          fontWeight: FontWeight.w700,
        ),
        const AppGap(12),
        Container(
          padding: Responsive.getPadding(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (var i = 0; i < breakdown.items.length; i++) ...[
                if (i > 0) const AppGap(14),
                _StatusBarRow(
                  item: breakdown.items[i],
                  fraction: breakdown.items[i].count / total,
                  trackColor: trackColor,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBarRow extends StatelessWidget {
  const _StatusBarRow({
    required this.item,
    required this.fraction,
    required this.trackColor,
  });

  final VehicleStatusBreakdownItem item;
  final double fraction;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                item.label,
                size: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppText(
              item.count.toString().padLeft(2, '0'),
              size: 13,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ],
        ),
        const AppGap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.getR(6)),
          child: SizedBox(
            height: Responsive.getH(10),
            child: Stack(
              children: [
                Container(color: trackColor),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: Container(color: item.color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
