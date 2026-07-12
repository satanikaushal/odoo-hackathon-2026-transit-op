import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/trip.dart';
import '../../domain/trip_formatters.dart';
import 'trip_status_badge.dart';

class TripDataTable extends StatelessWidget {
  const TripDataTable({
    super.key,
    required this.trips,
  });

  final List<Trip> trips;

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
          for (var i = 0; i < trips.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _DataRow(
              trip: trips[i],
              onTap: () => context.push(AppRoutes.tripDetail(trips[i].id)),
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
          Expanded(flex: 3, child: _HeaderCell('ROUTE')),
          Expanded(flex: 2, child: _HeaderCell('VEHICLE')),
          Expanded(flex: 2, child: _HeaderCell('DRIVER')),
          Expanded(flex: 2, child: _HeaderCell('CARGO')),
          Expanded(flex: 2, child: _HeaderCell('DISTANCE')),
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
    required this.trip,
    required this.onTap,
  });

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vehicle = trip.vehicle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: AppText(
                trip.routeLabel,
                size: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                vehicle?.registrationNumber ?? trip.vehicleId,
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(TripFormatters.driverLabel(trip), size: 12),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                TripFormatters.formatWeight(trip.cargoWeight),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                TripFormatters.formatDistance(trip.plannedDistance),
                size: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TripStatusBadge(status: trip.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
