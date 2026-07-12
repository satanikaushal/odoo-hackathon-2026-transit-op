import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/expenses_formatters.dart';
import '../../domain/models/fuel_log.dart';

class FuelLogListCard extends StatelessWidget {
  const FuelLogListCard({
    super.key,
    required this.log,
  });

  final FuelLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(Responsive.getR(12)),
      child: InkWell(
        onTap: () => context.push(AppRoutes.fuelLogDetail(log.id)),
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        child: Container(
          padding: Responsive.getPaddingSymmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                ExpensesFormatters.vehicleLabel(log),
                size: 15,
                fontWeight: FontWeight.w700,
              ),
              Responsive.verticalGap(6),
              AppText(
                '${ExpensesFormatters.formatLiters(log.liters)} · '
                '${ExpensesFormatters.formatMoney(log.cost)}',
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Responsive.verticalGap(4),
              AppText(
                ExpensesFormatters.formatDateTime(log.date),
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
