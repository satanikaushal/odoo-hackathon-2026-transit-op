import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_session_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/driver_detail_provider.dart';
import '../../domain/driver_formatters.dart';
import '../../domain/driver_permissions.dart';
import '../../domain/models/driver_status.dart';
import '../widgets/driver_status_badge.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({
    super.key,
    required this.driverId,
  });

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverDetailProvider(driverId));
    final notifier = ref.read(driverDetailProvider(driverId).notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageDrivers ?? false;

    if (state.isLoading && state.driver == null) {
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

    if (state.error != null && state.driver == null) {
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
                onPressed: () => notifier.load(driverId),
              ),
            ],
          ),
        ),
      );
    }

    final driver = state.driver!;
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
                      driver.name,
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  DriverStatusBadge(status: driver.status),
                ],
              ),
              if (driver.isLicenseExpired) ...[
                const AppGap(10),
                Container(
                  padding: Responsive.getPaddingSymmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.getR(8)),
                  ),
                  child: AppText(
                    'License expired — driver is blocked from trip assignment.',
                    size: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
              const AppGap(16),
              _DetailRow(label: 'License Number', value: driver.licenseNumber),
              _DetailRow(
                label: 'License Category',
                value: driver.licenseCategory,
              ),
              _DetailRow(
                label: 'License Expiry',
                value: DriverFormatters.formatExpiryDetail(driver),
                valueColor: driver.isLicenseExpired ? AppColors.error : null,
              ),
              _DetailRow(
                label: 'Contact',
                value: driver.contactNumber,
              ),
              _DetailRow(
                label: 'Safety Score',
                value: DriverFormatters.formatSafetyScore(driver.safetyScore),
              ),
            ],
          ),
        ),
        if (canManage) ...[
          const AppGap(20),
          _DriverActionsCard(
            isMutating: state.isMutating,
            onEdit: () => context.push(AppRoutes.driverEdit(driverId)),
            onChangeStatus: () =>
                _showStatusSheet(context, ref, driverId, driver.status),
            onDelete: () => _delete(context, ref, driverId),
          ),
        ],
        const AppGap(16),
      ],
    );
  }

  Future<void> _showStatusSheet(
    BuildContext context,
    WidgetRef ref,
    String driverId,
    DriverStatus current,
  ) async {
    final selected = await showModalBottomSheet<DriverStatus>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in DriverStatus.values)
                ListTile(
                  title: Text(status.label),
                  trailing: status == current
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == current || !context.mounted) {
      return;
    }

    final result = await ref
        .read(driverDetailProvider(driverId).notifier)
        .updateStatus(driverId, selected);

    if (!context.mounted) {
      return;
    }

    if (result.error != null) {
      if (result.statusCode == 409) {
        await showConflictDialog(context, message: result.error!);
      } else {
        showSnackBarMessage(context, result.error!);
      }
    } else {
      showSnackBarMessage(context, 'Status updated.');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete driver',
      message: 'This permanently removes the driver record.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result =
        await ref.read(driverDetailProvider(id).notifier).deleteDriver(id);
    if (!context.mounted) {
      return;
    }

    if (result.error == null) {
      showSnackBarMessage(context, 'Driver deleted.');
      context.go(AppRoutes.drivers);
      return;
    }

    if (result.suggestSuspend) {
      await showConflictDialog(
        context,
        message: result.error!,
        confirmLabel: 'Suspend instead',
        onConfirm: () async {
          final suspendResult = await ref
              .read(driverDetailProvider(id).notifier)
              .suspendDriver(id);
          if (context.mounted) {
            if (suspendResult.error == null) {
              showSnackBarMessage(context, 'Driver suspended.');
            } else if (suspendResult.statusCode == 409) {
              await showConflictDialog(
                context,
                message: suspendResult.error!,
              );
            } else {
              showSnackBarMessage(context, suspendResult.error!);
            }
          }
        },
      );
    } else {
      showSnackBarMessage(context, result.error!);
    }
  }
}

class _DriverActionsCard extends StatelessWidget {
  const _DriverActionsCard({
    required this.isMutating,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final bool isMutating;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

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
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Driver',
            enabled: !isMutating,
            onTap: onEdit,
          ),
          Divider(height: 1, color: borderColor),
          _ActionTile(
            icon: Icons.swap_horiz,
            label: 'Change Status',
            enabled: !isMutating,
            onTap: onChangeStatus,
          ),
          Divider(height: 1, color: borderColor),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete Driver',
            enabled: !isMutating,
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = textColor ?? theme.colorScheme.onSurface;

    return ListTile(
      dense: true,
      enabled: enabled,
      leading: Icon(
        icon,
        size: 20,
        color: enabled
            ? (iconColor ?? theme.colorScheme.onSurfaceVariant)
            : theme.disabledColor,
      ),
      title: AppText(
        label,
        size: 14,
        fontWeight: FontWeight.w500,
        color: enabled ? color : theme.disabledColor,
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: enabled ? onTap : null,
      contentPadding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
