import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/fleet_formatters.dart';
import '../../domain/models/vehicle_operational_cost.dart';

class VehicleOperationalCostCard extends StatelessWidget {
  const VehicleOperationalCostCard({
    super.key,
    required this.costs,
    required this.isLoading,
    this.error,
    this.onRetry,
  });

  final VehicleOperationalCost? costs;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
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
          AppText(
            'Operational Cost',
            size: 16,
            fontWeight: FontWeight.w700,
          ),
          Responsive.verticalGap(4),
          AppText(
            'Fuel + maintenance (excludes tolls and misc expenses)',
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const AppGap(16),
          if (isLoading && costs == null)
            AppShimmer(
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppShimmerBox(
                      height: Responsive.getH(18),
                      borderRadius: 6,
                    ),
                  ),
                ),
              ),
            )
          else if (error != null && costs == null)
            Column(
              children: [
                AppText(
                  error!,
                  size: 13,
                  textAlign: TextAlign.center,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (onRetry != null) ...[
                  const AppGap(12),
                  AppButton(
                    label: 'Retry',
                    expand: false,
                    onPressed: onRetry,
                  ),
                ],
              ],
            )
          else if (costs != null) ...[
            _CostRow(
              label: 'Fuel',
              value: FleetFormatters.formatCurrency(costs!.fuelCost),
            ),
            const AppGap(10),
            _CostRow(
              label: 'Maintenance',
              value: FleetFormatters.formatCurrency(costs!.maintenanceCost),
            ),
            const AppGap(10),
            _CostRow(
              label: 'Total',
              value: FleetFormatters.formatCurrency(costs!.operationalCost),
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            size: emphasized ? 14 : 13,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: emphasized
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppText(
          value,
          size: emphasized ? 16 : 14,
          fontWeight: FontWeight.w700,
          color: emphasized ? AppColors.primary : theme.colorScheme.onSurface,
        ),
      ],
    );
  }
}
