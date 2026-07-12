import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/expenses_formatters.dart';
import '../../domain/models/expense.dart';
import 'expense_category_badge.dart';

class ExpenseDataTable extends StatelessWidget {
  const ExpenseDataTable({
    super.key,
    required this.expenses,
  });

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.getPaddingSymmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _HeaderCell('VEHICLE')),
                Expanded(flex: 2, child: _HeaderCell('CATEGORY')),
                Expanded(flex: 3, child: _HeaderCell('DESCRIPTION')),
                Expanded(flex: 2, child: _HeaderCell('AMOUNT')),
                Expanded(flex: 2, child: _HeaderCell('DATE')),
              ],
            ),
          ),
          for (var i = 0; i < expenses.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            InkWell(
              onTap: () =>
                  context.push(AppRoutes.expenseRecordDetail(expenses[i].id)),
              child: Padding(
                padding:
                    Responsive.getPaddingSymmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppText(
                        expenses[i].vehicle?.registrationNumber ??
                            expenses[i].vehicleId,
                        size: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ExpenseCategoryBadge(
                          category: expenses[i].category,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: AppText(
                        expenses[i].description ?? '—',
                        size: 12,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        ExpensesFormatters.formatMoney(expenses[i].amount),
                        size: 12,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        ExpensesFormatters.formatDateTime(expenses[i].date),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      size: 10,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
