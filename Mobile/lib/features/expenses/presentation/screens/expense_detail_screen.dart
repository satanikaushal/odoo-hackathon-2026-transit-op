import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/expense_detail_provider.dart';
import '../../domain/expenses_formatters.dart';
import '../widgets/expense_category_badge.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseDetailProvider(expenseId));
    final notifier = ref.read(expenseDetailProvider(expenseId).notifier);

    if (state.isLoading && state.expense == null) {
      return ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          AppShimmer(
            child: AppShimmerBox(
              height: Responsive.getH(280),
              borderRadius: 12,
            ),
          ),
        ],
      );
    }

    if (state.error != null && state.expense == null) {
      return Center(
        child: Padding(
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(state.error!, size: 14, textAlign: TextAlign.center),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                expand: false,
                onPressed: () => notifier.load(expenseId),
              ),
            ],
          ),
        ),
      );
    }

    final expense = state.expense!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        Container(
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      ExpensesFormatters.vehicleLabelForExpense(expense),
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ExpenseCategoryBadge(category: expense.category),
                ],
              ),
              const AppGap(16),
              _DetailRow(
                label: 'Amount',
                value: ExpensesFormatters.formatMoney(expense.amount),
              ),
              if (expense.description?.isNotEmpty == true)
                _DetailRow(label: 'Description', value: expense.description!),
              _DetailRow(
                label: 'Date',
                value: ExpensesFormatters.formatDateTime(expense.date),
              ),
              if (expense.tripId != null)
                _DetailRow(label: 'Trip ID', value: expense.tripId!),
              _DetailRow(
                label: 'Recorded',
                value: ExpensesFormatters.formatDateTime(expense.createdAt),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              size: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
