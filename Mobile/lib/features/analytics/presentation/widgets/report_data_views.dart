import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/analytics_formatters.dart';
import '../../domain/models/fuel_efficiency_row.dart';
import '../../domain/models/operational_cost_row.dart';
import '../../domain/models/vehicle_roi_row.dart';

class ReportListCard extends StatelessWidget {
  const ReportListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  title,
                  size: 15,
                  fontWeight: FontWeight.w700,
                ),
                Responsive.verticalGap(4),
                AppText(
                  subtitle,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppText(
            trailing,
            size: 13,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class FuelEfficiencyList extends StatelessWidget {
  const FuelEfficiencyList({super.key, required this.rows});

  final List<FuelEfficiencyRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Responsive.verticalGap(10),
          ReportListCard(
            title: '${rows[i].registrationNumber} · ${rows[i].name}',
            subtitle:
                '${AnalyticsFormatters.formatDistance(rows[i].totalDistance)} · '
                '${AnalyticsFormatters.formatLiters(rows[i].totalLiters)}',
            trailing: AnalyticsFormatters.formatKmPerLiter(rows[i].kmPerLiter),
          ),
        ],
      ],
    );
  }
}

class OperationalCostList extends StatelessWidget {
  const OperationalCostList({super.key, required this.rows});

  final List<OperationalCostRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Responsive.verticalGap(10),
          ReportListCard(
            title: '${rows[i].registrationNumber} · ${rows[i].name}',
            subtitle:
                'Fuel ${AnalyticsFormatters.formatCurrency(rows[i].fuelCost)} · '
                'Maint. ${AnalyticsFormatters.formatCurrency(rows[i].maintenanceCost)}',
            trailing:
                AnalyticsFormatters.formatCurrency(rows[i].operationalCost),
          ),
        ],
      ],
    );
  }
}

class VehicleRoiList extends StatelessWidget {
  const VehicleRoiList({super.key, required this.rows});

  final List<VehicleRoiRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Responsive.verticalGap(10),
          ReportListCard(
            title: '${rows[i].registrationNumber} · ${rows[i].name}',
            subtitle:
                'Revenue ${AnalyticsFormatters.formatCurrency(rows[i].totalRevenue)} · '
                'Profit ${AnalyticsFormatters.formatCurrency(rows[i].netProfit)}',
            trailing: AnalyticsFormatters.formatRoi(rows[i].roi),
          ),
        ],
      ],
    );
  }
}

class FuelEfficiencyTable extends StatelessWidget {
  const FuelEfficiencyTable({super.key, required this.rows});

  final List<FuelEfficiencyRow> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      headers: const ['REG. NO.', 'NAME', 'DISTANCE', 'LITERS', 'KM/L'],
      rows: rows
          .map(
            (row) => [
              row.registrationNumber,
              row.name,
              AnalyticsFormatters.formatDistance(row.totalDistance),
              AnalyticsFormatters.formatLiters(row.totalLiters),
              AnalyticsFormatters.formatKmPerLiter(row.kmPerLiter),
            ],
          )
          .toList(),
    );
  }
}

class OperationalCostTable extends StatelessWidget {
  const OperationalCostTable({super.key, required this.rows});

  final List<OperationalCostRow> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      headers: const ['REG. NO.', 'NAME', 'FUEL', 'MAINT.', 'TOTAL'],
      rows: rows
          .map(
            (row) => [
              row.registrationNumber,
              row.name,
              AnalyticsFormatters.formatCurrency(row.fuelCost),
              AnalyticsFormatters.formatCurrency(row.maintenanceCost),
              AnalyticsFormatters.formatCurrency(row.operationalCost),
            ],
          )
          .toList(),
    );
  }
}

class VehicleRoiTable extends StatelessWidget {
  const VehicleRoiTable({super.key, required this.rows});

  final List<VehicleRoiRow> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      headers: const [
        'REG. NO.',
        'NAME',
        'REVENUE',
        'OPEX',
        'NET',
        'ROI',
      ],
      rows: rows
          .map(
            (row) => [
              row.registrationNumber,
              row.name,
              AnalyticsFormatters.formatCurrency(row.totalRevenue),
              AnalyticsFormatters.formatCurrency(row.operationalCost),
              AnalyticsFormatters.formatCurrency(row.netProfit),
              AnalyticsFormatters.formatRoi(row.roi),
            ],
          )
          .toList(),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

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
            child: Row(
              children: [
                for (final header in headers)
                  Expanded(
                    child: AppText(
                      header,
                      size: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            Padding(
              padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final cell in rows[i])
                    Expanded(
                      child: AppText(cell, size: 12),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
