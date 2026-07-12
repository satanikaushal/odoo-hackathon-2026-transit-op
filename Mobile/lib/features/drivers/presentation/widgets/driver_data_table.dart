import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/driver_formatters.dart';
import '../../domain/models/driver.dart';
import 'driver_status_badge.dart';

class DriverDataTable extends StatelessWidget {
  const DriverDataTable({
    super.key,
    required this.drivers,
  });

  final List<Driver> drivers;

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
          for (var i = 0; i < drivers.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _DataRow(
              driver: drivers[i],
              onTap: () => context.push(AppRoutes.driverDetail(drivers[i].id)),
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
          Expanded(flex: 2, child: _HeaderCell('NAME')),
          Expanded(flex: 2, child: _HeaderCell('LICENSE')),
          Expanded(flex: 2, child: _HeaderCell('CATEGORY')),
          Expanded(flex: 2, child: _HeaderCell('EXPIRY')),
          Expanded(flex: 2, child: _HeaderCell('CONTACT')),
          Expanded(flex: 2, child: _HeaderCell('SAFETY')),
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
    required this.driver,
    required this.onTap,
  });

  final Driver driver;
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
                driver.name,
                size: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(driver.licenseNumber, size: 12),
            ),
            Expanded(
              flex: 2,
              child: AppText(driver.licenseCategory, size: 12),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  AppText(
                    DriverFormatters.formatExpiry(driver),
                    size: 12,
                    color: driver.isLicenseExpired ? AppColors.error : null,
                    fontWeight:
                        driver.isLicenseExpired ? FontWeight.w700 : null,
                  ),
                  if (driver.isLicenseExpired) ...[
                    const SizedBox(width: 4),
                    AppText(
                      'EXPIRE',
                      size: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                DriverFormatters.maskContact(driver.contactNumber),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                DriverFormatters.formatSafetyScore(driver.safetyScore),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: DriverStatusBadge(status: driver.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
