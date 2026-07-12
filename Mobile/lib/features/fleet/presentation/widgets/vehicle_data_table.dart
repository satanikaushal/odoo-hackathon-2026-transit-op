import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/fleet_formatters.dart';
import '../../domain/models/vehicle.dart';
import 'vehicle_status_badge.dart';

class VehicleDataTable extends StatelessWidget {
  const VehicleDataTable({
    super.key,
    required this.vehicles,
  });

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _HeaderRow(borderColor: borderColor, muted: muted),
          for (var i = 0; i < vehicles.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _DataRow(
              vehicle: vehicles[i],
              onTap: () => context.push(AppRoutes.fleetDetail(vehicles[i].id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.borderColor,
    required this.muted,
  });

  final Color borderColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('REG. NO.')),
          Expanded(flex: 2, child: _HeaderCell('NAME/MODEL')),
          Expanded(flex: 2, child: _HeaderCell('TYPE')),
          Expanded(flex: 2, child: _HeaderCell('CAPACITY')),
          Expanded(flex: 2, child: _HeaderCell('ODOMETER')),
          Expanded(flex: 2, child: _HeaderCell('ACQ. COST')),
          Expanded(flex: 2, child: _HeaderCell('STATUS')),
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

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.vehicle,
    required this.onTap,
  });

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: AppText(
                vehicle.registrationNumber,
                size: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(flex: 2, child: AppText(vehicle.name, size: 12)),
            Expanded(flex: 2, child: AppText(vehicle.type, size: 12)),
            Expanded(
              flex: 2,
              child: AppText(
                FleetFormatters.formatCapacity(vehicle.maxLoadCapacity),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                FleetFormatters.formatOdometer(vehicle.odometer),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                FleetFormatters.formatCurrency(vehicle.acquisitionCost),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: VehicleStatusBadge(status: vehicle.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
