import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/maintenance_formatters.dart';
import '../../domain/models/maintenance_log.dart';
import 'maintenance_status_badge.dart';

class MaintenanceListCard extends StatelessWidget {
  const MaintenanceListCard({
    super.key,
    required this.log,
  });

  final MaintenanceLog log;

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
        onTap: () => context.push(AppRoutes.maintenanceDetail(log.id)),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText(
                      MaintenanceFormatters.vehicleLabel(log),
                      size: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  MaintenanceStatusBadge(status: log.status),
                ],
              ),
              Responsive.verticalGap(6),
              AppText(
                log.description,
                size: 13,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Responsive.verticalGap(4),
              AppText(
                '${MaintenanceFormatters.formatCost(log.cost)} · '
                'Opened ${MaintenanceFormatters.formatDateTime(log.openedAt)}',
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
