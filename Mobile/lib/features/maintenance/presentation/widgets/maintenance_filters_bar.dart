import 'package:flutter/material.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/maintenance_status.dart';

class MaintenanceFiltersBar extends StatelessWidget {
  const MaintenanceFiltersBar({
    super.key,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<MaintenanceStatus> statusOptions;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Status',
        contentPadding: Responsive.getPaddingSymmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedStatus,
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
            ...statusOptions.map(
              (status) => DropdownMenuItem<String?>(
                value: status.name,
                child: Text(status.label),
              ),
            ),
          ],
          onChanged: onStatusChanged,
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
