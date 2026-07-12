import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/trip_status.dart';

class TripFiltersBar extends StatelessWidget {
  const TripFiltersBar({
    super.key,
    required this.statusOptions,
    required this.selectedStatus,
    required this.searchController,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final List<TripStatus> statusOptions;
  final String? selectedStatus;
  final TextEditingController searchController;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterDropdown(
          label: 'Status',
          value: selectedStatus,
          items: statusOptions
              .map(
                (status) => DropdownMenuItem<String?>(
                  value: status.name,
                  child: Text(status.label),
                ),
              )
              .toList(),
          onChanged: onStatusChanged,
        ),
        const AppGap(10),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search',
            hintText: 'Search source or destination...',
            contentPadding: Responsive.getPaddingSymmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: Responsive.getPaddingSymmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: value,
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
            ...items,
          ],
          onChanged: onChanged,
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
