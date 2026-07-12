import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Full-page shimmer for the first load (filters + list).
class FleetListShimmer extends StatelessWidget {
  const FleetListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FleetFiltersShimmer(),
        const AppGap(16),
        FleetListItemsShimmer(itemCount: itemCount),
      ],
    );
  }
}

/// Shimmer for filter + search bar only.
class FleetFiltersShimmer extends StatelessWidget {
  const FleetFiltersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
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
            height: Responsive.getH(48),
            borderRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Shimmer for vehicle rows only — used when filters stay visible during refresh.
class FleetListItemsShimmer extends StatelessWidget {
  const FleetListItemsShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const AppGap(10),
            AppShimmerBox(
              height: Responsive.getH(88),
              borderRadius: 12,
            ),
          ],
        ],
      ),
    );
  }
}
