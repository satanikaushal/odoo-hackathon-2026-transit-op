import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_gap.dart';

class ExpensesListShimmer extends StatelessWidget {
  const ExpensesListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppShimmer(
          child: AppShimmerBox(
            height: Responsive.getH(52),
            borderRadius: 8,
          ),
        ),
        const AppGap(16),
        ExpensesListItemsShimmer(itemCount: itemCount),
      ],
    );
  }
}

class ExpensesListItemsShimmer extends StatelessWidget {
  const ExpensesListItemsShimmer({super.key, this.itemCount = 4});

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
