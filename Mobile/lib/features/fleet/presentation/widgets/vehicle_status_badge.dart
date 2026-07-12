import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../domain/models/vehicle_status.dart';

class VehicleStatusBadge extends StatelessWidget {
  const VehicleStatusBadge({
    super.key,
    required this.status,
  });

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      VehicleStatus.AVAILABLE => (
          AppColors.available.withValues(alpha: 0.15),
          AppColors.available,
        ),
      VehicleStatus.ON_TRIP => (
          AppColors.onTrip.withValues(alpha: 0.15),
          AppColors.onTrip,
        ),
      VehicleStatus.IN_SHOP => (
          AppColors.inShop.withValues(alpha: 0.15),
          AppColors.inShop,
        ),
      VehicleStatus.RETIRED => (
          AppColors.retired.withValues(alpha: 0.15),
          AppColors.retired,
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
