import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';

class AnalyticsReportShimmer extends StatelessWidget {
  const AnalyticsReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          AppShimmerBox(
            height: Responsive.getH(52),
            borderRadius: 8,
          ),
          const AppGap(16),
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const AppGap(10),
            AppShimmerBox(
              height: Responsive.getH(72),
              borderRadius: 12,
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyticsReportItemsShimmer extends StatelessWidget {
  const AnalyticsReportItemsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const AppGap(10),
            AppShimmerBox(
              height: Responsive.getH(72),
              borderRadius: 12,
            ),
          ],
        ],
      ),
    );
  }
}
