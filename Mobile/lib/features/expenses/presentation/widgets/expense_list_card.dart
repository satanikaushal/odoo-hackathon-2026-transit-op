import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/expenses_formatters.dart';
import '../../domain/models/expense.dart';
import 'expense_category_badge.dart';

class ExpenseListCard extends StatelessWidget {
  const ExpenseListCard({
    super.key,
    required this.expense,
  });

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(Responsive.getR(12)),
      child: InkWell(
        onTap: () => context.push(AppRoutes.expenseRecordDetail(expense.id)),
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        child: Container(
          padding: Responsive.getPaddingSymmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      ExpensesFormatters.vehicleLabelForExpense(expense),
                      size: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ExpenseCategoryBadge(category: expense.category),
                ],
              ),
              Responsive.verticalGap(6),
              AppText(
                expense.description?.isNotEmpty == true
                    ? expense.description!
                    : expense.category.label,
                size: 13,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Responsive.verticalGap(4),
              AppText(
                '${ExpensesFormatters.formatMoney(expense.amount)} · '
                '${ExpensesFormatters.formatDateTime(expense.date)}',
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
