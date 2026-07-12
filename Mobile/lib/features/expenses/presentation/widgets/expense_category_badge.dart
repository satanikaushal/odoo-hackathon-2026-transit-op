import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/expense_category.dart';

class ExpenseCategoryBadge extends StatelessWidget {
  const ExpenseCategoryBadge({
    super.key,
    required this.category,
  });

  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (category) {
      ExpenseCategory.toll => AppColors.primary,
      ExpenseCategory.misc => isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
    };

    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Responsive.getR(6)),
      ),
      child: AppText(
        category.label.toUpperCase(),
        size: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
