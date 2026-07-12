import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/expenses_formatters.dart';
import '../../domain/models/fuel_log.dart';

class FuelLogDataTable extends StatelessWidget {
  const FuelLogDataTable({
    super.key,
    required this.logs,
  });

  final List<FuelLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _HeaderCell('VEHICLE')),
                Expanded(flex: 2, child: _HeaderCell('LITERS')),
                Expanded(flex: 2, child: _HeaderCell('COST')),
                Expanded(flex: 2, child: _HeaderCell('DATE')),
              ],
            ),
          ),
          for (var i = 0; i < logs.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            InkWell(
              onTap: () => context.push(AppRoutes.fuelLogDetail(logs[i].id)),
              child: Padding(
                padding:
                    Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppText(
                        logs[i].vehicle?.registrationNumber ?? logs[i].vehicleId,
                        size: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        ExpensesFormatters.formatLiters(logs[i].liters),
                        size: 12,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        ExpensesFormatters.formatMoney(logs[i].cost),
                        size: 12,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        ExpensesFormatters.formatDateTime(logs[i].date),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      size: 10,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
