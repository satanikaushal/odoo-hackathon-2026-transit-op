import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/driver_formatters.dart';
import '../../domain/models/driver.dart';
import 'driver_status_badge.dart';

class DriverListCard extends StatelessWidget {
  const DriverListCard({
    super.key,
    required this.driver,
  });

  final Driver driver;

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
        onTap: () => context.push(AppRoutes.driverDetail(driver.id)),
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
                      driver.name,
                      size: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  DriverStatusBadge(status: driver.status),
                ],
              ),
              Responsive.verticalGap(6),
              AppText(
                '${driver.licenseNumber} · ${driver.licenseCategory}',
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Responsive.verticalGap(4),
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      'Expiry ${DriverFormatters.formatExpiry(driver)} · '
                      'Safety ${DriverFormatters.formatSafetyScore(driver.safetyScore)}',
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (driver.isLicenseExpired)
                    AppText(
                      'EXPIRE',
                      size: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
