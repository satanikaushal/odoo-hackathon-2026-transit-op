import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../domain/models/driver_status.dart';

class DriverStatusBadge extends StatelessWidget {
  const DriverStatusBadge({
    super.key,
    required this.status,
  });

  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      DriverStatus.AVAILABLE => (
          AppColors.available.withValues(alpha: 0.15),
          AppColors.available,
        ),
      DriverStatus.ON_TRIP => (
          AppColors.onTrip.withValues(alpha: 0.15),
          AppColors.onTrip,
        ),
      DriverStatus.OFF_DUTY => (
          AppColors.offDuty.withValues(alpha: 0.15),
          AppColors.offDuty,
        ),
      DriverStatus.SUSPENDED => (
          AppColors.suspended.withValues(alpha: 0.15),
          AppColors.suspended,
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
