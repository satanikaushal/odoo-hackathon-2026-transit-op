import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/maintenance_formatters.dart';
import '../../domain/models/maintenance_log.dart';
import 'maintenance_status_badge.dart';

class MaintenanceDataTable extends StatelessWidget {
  const MaintenanceDataTable({
    super.key,
    required this.logs,
  });

  final List<MaintenanceLog> logs;

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
          _HeaderRow(borderColor: borderColor),
          for (var i = 0; i < logs.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _DataRow(
              log: logs[i],
              onTap: () => context.push(AppRoutes.maintenanceDetail(logs[i].id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('VEHICLE')),
          Expanded(flex: 3, child: _HeaderCell('DESCRIPTION')),
          Expanded(flex: 2, child: _HeaderCell('COST')),
          Expanded(flex: 2, child: _HeaderCell('OPENED')),
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
    required this.log,
    required this.onTap,
  });

  final MaintenanceLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vehicle = log.vehicle;

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
                vehicle?.registrationNumber ?? log.vehicleId,
                size: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              flex: 3,
              child: AppText(
                log.description,
                size: 12,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                MaintenanceFormatters.formatCost(log.cost),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                MaintenanceFormatters.formatDateTime(log.openedAt),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: MaintenanceStatusBadge(status: log.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
