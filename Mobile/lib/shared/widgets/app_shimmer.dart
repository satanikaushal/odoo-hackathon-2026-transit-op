import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../utils/responsive.dart';

/// Theme-aware shimmer wrapper used across list/detail loading states.
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  static (Color base, Color highlight) colorsOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return (AppColors.darkSurfaceVariant, AppColors.darkBorder);
    }
    return (AppColors.lightSurfaceVariant, AppColors.lightBorder);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final (base, highlight) = colorsOf(context);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}

/// A single rounded placeholder block for skeleton layouts.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(Responsive.getR(borderRadius)),
      ),
    );
  }
}

/// Generic bottom-of-list shimmer row for infinite-scroll pagination.
class AppShimmerListFooter extends StatelessWidget {
  const AppShimmerListFooter({
    super.key,
    this.itemHeight = 72,
    this.itemCount = 2,
  });

  final double itemHeight;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: Responsive.getH(10)),
            AppShimmerBox(
              width: double.infinity,
              height: Responsive.getH(itemHeight),
              borderRadius: 12,
            ),
          ],
        ],
      ),
    );
  }
}
