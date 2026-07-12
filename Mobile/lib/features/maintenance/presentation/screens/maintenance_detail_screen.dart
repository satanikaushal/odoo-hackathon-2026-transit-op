import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_session_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/maintenance_detail_provider.dart';
import '../../domain/maintenance_formatters.dart';
import '../../domain/maintenance_permissions.dart';
import '../../domain/models/maintenance_status.dart';
import '../widgets/maintenance_status_badge.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  const MaintenanceDetailScreen({
    super.key,
    required this.logId,
  });

  final String logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceDetailProvider(logId));
    final notifier = ref.read(maintenanceDetailProvider(logId).notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageMaintenance ?? false;

    if (state.isLoading && state.log == null) {
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

    if (state.error != null && state.log == null) {
      return Center(
        child: Padding(
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                state.error!,
                size: 14,
                textAlign: TextAlign.center,
              ),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                expand: false,
                onPressed: () => notifier.load(logId),
              ),
            ],
          ),
        ),
      );
    }

    final log = state.log!;
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
                      MaintenanceFormatters.vehicleLabel(log),
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  MaintenanceStatusBadge(status: log.status),
                ],
              ),
              const AppGap(16),
              _DetailRow(label: 'Description', value: log.description),
              _DetailRow(
                label: 'Cost',
                value: MaintenanceFormatters.formatCost(log.cost),
              ),
              _DetailRow(
                label: 'Opened At',
                value: MaintenanceFormatters.formatDateTime(log.openedAt),
              ),
              if (log.closedAt != null)
                _DetailRow(
                  label: 'Closed At',
                  value: MaintenanceFormatters.formatDateTime(log.closedAt!),
                ),
            ],
          ),
        ),
        if (canManage && log.status == MaintenanceStatus.OPEN) ...[
          const AppGap(20),
          _MaintenanceActionsCard(
            isMutating: state.isMutating,
            onClose: () => _close(context, ref, logId),
          ),
        ],
        const AppGap(16),
      ],
    );
  }

  Future<void> _close(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Close maintenance',
      message:
          'This closes the record and may release the vehicle to Available if no other open logs remain.',
      confirmLabel: 'Close Record',
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result =
        await ref.read(maintenanceDetailProvider(id).notifier).closeLog(id);
    if (!context.mounted) {
      return;
    }

    if (result.error != null) {
      if (result.statusCode == 409) {
        await showConflictDialog(context, message: result.error!);
      } else {
        showSnackBarMessage(context, result.error!);
      }
      return;
    }

    showSnackBarMessage(context, 'Maintenance record closed.');
  }
}

class _MaintenanceActionsCard extends StatelessWidget {
  const _MaintenanceActionsCard({
    required this.isMutating,
    required this.onClose,
  });

  final bool isMutating;
  final VoidCallback onClose;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 12),
            child: AppText(
              'Actions',
              size: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            dense: true,
            enabled: !isMutating,
            leading: Icon(
              Icons.check_circle_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: AppText(
              'Close Maintenance',
              size: 14,
              fontWeight: FontWeight.w500,
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: isMutating ? null : onClose,
            contentPadding:
                Responsive.getPaddingSymmetric(horizontal: 16, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              size: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
