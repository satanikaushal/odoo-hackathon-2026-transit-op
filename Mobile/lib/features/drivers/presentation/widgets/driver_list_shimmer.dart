import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';

class DriverListShimmer extends StatelessWidget {
  const DriverListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DriverFiltersShimmer(),
        const AppGap(16),
        DriverListItemsShimmer(itemCount: itemCount),
      ],
    );
  }
}

class DriverFiltersShimmer extends StatelessWidget {
  const DriverFiltersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          AppShimmerBox(
            height: Responsive.getH(52),
            borderRadius: 8,
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

class DriverListItemsShimmer extends StatelessWidget {
  const DriverListItemsShimmer({super.key, this.itemCount = 4});

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
