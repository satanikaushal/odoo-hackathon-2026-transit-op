import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/models/dashboard_filter_options.dart';

class DashboardFiltersSection extends StatelessWidget {
  const DashboardFiltersSection({
    super.key,
    required this.options,
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedRegion,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onRegionChanged,
  });

  final DashboardFilterOptions options;
  final String? selectedType;
  final String? selectedStatus;
  final String? selectedRegion;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onRegionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'FILTERS',
          size: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const AppGap(12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'Vehicle Type',
                value: selectedType,
                items: options.types,
                onChanged: onTypeChanged,
              ),
            ),
            Responsive.horizontalGap(10),
            Expanded(
              child: _FilterDropdown(
                label: 'Status',
                value: selectedStatus,
                items: options.statuses,
                onChanged: onStatusChanged,
                formatItemLabel: (item) => item.replaceAll('_', ' '),
              ),
            ),
          ],
        ),
        const AppGap(10),
        _FilterDropdown(
          label: 'Region',
          value: selectedRegion,
          items: options.regions,
          onChanged: onRegionChanged,
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
    this.formatItemLabel,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String item)? formatItemLabel;

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
            ...items.map(
              (item) => DropdownMenuItem<String?>(
                value: item,
                child: Text(formatItemLabel?.call(item) ?? item),
              ),
            ),
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

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: Responsive.getPaddingSymmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      label,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Responsive.verticalGap(6),
                    AppText(
                      value,
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardKpiList extends StatelessWidget {
  const DashboardKpiList({
    super.key,
    required this.items,
  });

  final List<({String label, String value, Color accent})> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const AppGap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DashboardKpiCard(
                  label: items[i].label,
                  value: items[i].value,
                  accentColor: items[i].accent,
                ),
              ),
              if (i + 1 < items.length) ...[
                Responsive.horizontalGap(10),
                Expanded(
                  child: DashboardKpiCard(
                    label: items[i + 1].label,
                    value: items[i + 1].value,
                    accentColor: items[i + 1].accent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
