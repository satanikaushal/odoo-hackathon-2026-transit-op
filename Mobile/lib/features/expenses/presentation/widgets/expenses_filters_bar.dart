import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/expense_category.dart';

class ExpensesFiltersBar extends StatelessWidget {
  const ExpensesFiltersBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Category',
        contentPadding: Responsive.getPaddingSymmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedCategory,
          hint: AppText(
            'All',
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All'),
            ),
            ...ExpenseCategory.values.map(
              (category) => DropdownMenuItem<String?>(
                value: category.apiValue,
                child: Text(category.label),
              ),
            ),
          ],
          onChanged: onCategoryChanged,
          style: TextStyle(
            fontSize: Responsive.getF(14),
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}
