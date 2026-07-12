import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/dashboard_trip_summary.dart';

class DashboardRecentTripsSection extends StatelessWidget {
  const DashboardRecentTripsSection({
    super.key,
    required this.trips,
  });

  final List<DashboardTripSummary> trips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Recent Trips',
          size: 16,
          fontWeight: FontWeight.w700,
        ),
        const AppGap(12),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _TripsHeader(borderColor: borderColor),
              for (var i = 0; i < trips.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: borderColor),
                _TripRow(trip: trips[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('TRIP', muted)),
          Expanded(flex: 2, child: _HeaderCell('VEHICLE', muted)),
          Expanded(flex: 2, child: _HeaderCell('DRIVER', muted)),
          Expanded(flex: 3, child: _HeaderCell('STATUS', muted)),
          Expanded(flex: 2, child: _HeaderCell('ETA', muted, alignEnd: true)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, this.color, {this.alignEnd = false});

  final String text;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      size: 10,
      fontWeight: FontWeight.w700,
      color: color,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final DashboardTripSummary trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: AppText(trip.tripId, size: 12, fontWeight: FontWeight.w600),
          ),
          Expanded(
            flex: 2,
            child: AppText(trip.vehicle, size: 12),
          ),
          Expanded(
            flex: 2,
            child: AppText(trip.driver, size: 12),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: trip.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: AppText(
              trip.eta,
              size: 11,
              textAlign: TextAlign.end,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripSummaryStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      TripSummaryStatus.onTrip => (
          AppColors.onTrip.withValues(alpha: 0.15),
          AppColors.onTrip,
        ),
      TripSummaryStatus.completed => (
          AppColors.completed.withValues(alpha: 0.15),
          AppColors.completed,
        ),
      TripSummaryStatus.dispatched => (
          AppColors.dispatched.withValues(alpha: 0.15),
          AppColors.dispatched,
        ),
      TripSummaryStatus.draft => (
          AppColors.draft.withValues(alpha: 0.15),
          AppColors.draft,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Responsive.getR(6)),
      ),
      child: AppText(
        status.label,
        size: 10,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
  }
}
