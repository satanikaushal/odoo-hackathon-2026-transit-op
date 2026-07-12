import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/fleet_formatters.dart';
import '../../domain/models/vehicle.dart';
import 'vehicle_status_badge.dart';

class VehicleListCard extends StatelessWidget {
  const VehicleListCard({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

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
        onTap: () => context.push(AppRoutes.fleetDetail(vehicle.id)),
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
                      vehicle.registrationNumber,
                      size: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  VehicleStatusBadge(status: vehicle.status),
                ],
              ),
              Responsive.verticalGap(6),
              AppText(
                '${vehicle.name} · ${vehicle.type}',
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Responsive.verticalGap(4),
              AppText(
                '${FleetFormatters.formatCapacity(vehicle.maxLoadCapacity)} · '
                '${FleetFormatters.formatOdometer(vehicle.odometer)} · '
                '${FleetFormatters.formatCurrency(vehicle.acquisitionCost)}',
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
