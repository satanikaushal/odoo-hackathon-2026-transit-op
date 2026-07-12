import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Skeleton for the dashboard filters + KPI grid while data loads.
class DashboardLoadingShimmer extends StatelessWidget {
  const DashboardLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppShimmerBox(
            width: Responsive.getW(56),
            height: Responsive.getH(12),
            borderRadius: 4,
          ),
          const AppGap(12),
          Row(
            children: [
              Expanded(
                child: AppShimmerBox(
                  height: Responsive.getH(52),
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: Responsive.getW(10)),
              Expanded(
                child: AppShimmerBox(
                  height: Responsive.getH(52),
                  borderRadius: 8,
                ),
              ),
            ],
          ),
          const AppGap(10),
          AppShimmerBox(
            height: Responsive.getH(52),
            borderRadius: 8,
          ),
          const AppGap(20),
          const DashboardKpiLoadingShimmer(enableShimmer: false),
        ],
      ),
    );
  }
}

/// Skeleton for the 2-column KPI card grid (7 cards).
class DashboardKpiLoadingShimmer extends StatelessWidget {
  const DashboardKpiLoadingShimmer({
    super.key,
    this.enableShimmer = true,
  });

  final bool enableShimmer;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        for (var row = 0; row < 4; row++) ...[
          if (row > 0) const AppGap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppShimmerBox(
                  height: Responsive.getH(72),
                  borderRadius: 12,
                ),
              ),
              if (row < 3) ...[
                SizedBox(width: Responsive.getW(10)),
                Expanded(
                  child: AppShimmerBox(
                    height: Responsive.getH(72),
                    borderRadius: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );

    if (!enableShimmer) {
      return content;
    }

    return AppShimmer(child: content);
  }
}
