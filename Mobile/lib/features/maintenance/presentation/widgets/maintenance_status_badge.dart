import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../domain/models/maintenance_status.dart';

class MaintenanceStatusBadge extends StatelessWidget {
  const MaintenanceStatusBadge({
    super.key,
    required this.status,
  });

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      MaintenanceStatus.OPEN => (
          AppColors.inShop.withValues(alpha: 0.15),
          AppColors.inShop,
        ),
      MaintenanceStatus.CLOSED => (
          AppColors.offDuty.withValues(alpha: 0.15),
          AppColors.offDuty,
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
