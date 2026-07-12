import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../domain/models/trip_status.dart';

class TripStatusBadge extends StatelessWidget {
  const TripStatusBadge({
    super.key,
    required this.status,
  });

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      TripStatus.DRAFT => (
          AppColors.draft.withValues(alpha: 0.15),
          AppColors.draft,
        ),
      TripStatus.DISPATCHED => (
          AppColors.dispatched.withValues(alpha: 0.15),
          AppColors.dispatched,
        ),
      TripStatus.COMPLETED => (
          AppColors.completed.withValues(alpha: 0.15),
          AppColors.completed,
        ),
      TripStatus.CANCELLED => (
          AppColors.cancelled.withValues(alpha: 0.15),
          AppColors.cancelled,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Responsive.getR(6)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: Responsive.getF(10),
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
