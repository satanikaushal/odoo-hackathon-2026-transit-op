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
import '../../application/vehicle_detail_provider.dart';
import '../../domain/fleet_formatters.dart';
import '../../domain/fleet_permissions.dart';
import '../../domain/models/vehicle_status.dart';
import '../widgets/vehicle_operational_cost_card.dart';
import '../widgets/vehicle_status_badge.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleDetailProvider(vehicleId));
    final notifier = ref.read(vehicleDetailProvider(vehicleId).notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageFleet ?? false;

    if (state.isLoading && state.vehicle == null) {
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

    if (state.error != null && state.vehicle == null) {
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
                onPressed: () => notifier.load(vehicleId),
              ),
            ],
          ),
        ),
      );
    }

    final vehicle = state.vehicle!;
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
                      vehicle.registrationNumber,
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  VehicleStatusBadge(status: vehicle.status),
                ],
              ),
              const AppGap(16),
              _DetailRow(label: 'Name / Model', value: vehicle.name),
              _DetailRow(label: 'Type', value: vehicle.type),
              _DetailRow(
                label: 'Capacity',
                value: FleetFormatters.formatCapacity(vehicle.maxLoadCapacity),
              ),
              _DetailRow(
                label: 'Odometer',
                value: FleetFormatters.formatOdometer(vehicle.odometer),
              ),
              _DetailRow(
                label: 'Acquisition Cost',
                value: FleetFormatters.formatCurrency(vehicle.acquisitionCost),
              ),
              _DetailRow(label: 'Region', value: vehicle.region ?? '—'),
            ],
          ),
        ),
        const AppGap(16),
        VehicleOperationalCostCard(
          costs: state.operationalCost,
          isLoading: state.isCostsLoading,
          error: state.costsError,
          onRetry: () => notifier.loadCosts(vehicleId),
        ),
        if (canManage) ...[
          const AppGap(20),
          _VehicleActionsCard(
            isMutating: state.isMutating,
            onEdit: () => context.push(AppRoutes.fleetEdit(vehicleId)),
            onChangeStatus: () =>
                _showStatusSheet(context, ref, vehicleId, vehicle.status),
            onRetire: () => _retire(context, ref, vehicleId),
            onDelete: () => _delete(context, ref, vehicleId),
          ),
        ],
        const AppGap(16),
      ],
    );
  }

  Future<void> _showStatusSheet(
    BuildContext context,
    WidgetRef ref,
    String vehicleId,
    VehicleStatus current,
  ) async {
    final selected = await showModalBottomSheet<VehicleStatus>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in VehicleStatus.values)
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
        .read(vehicleDetailProvider(vehicleId).notifier)
        .updateStatus(vehicleId, selected);

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

  Future<void> _retire(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Retire vehicle',
      message: 'This vehicle will be marked as Retired and removed from dispatch.',
      confirmLabel: 'Retire',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result =
        await ref.read(vehicleDetailProvider(id).notifier).retireVehicle(id);
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

    showSnackBarMessage(context, 'Vehicle retired.');
    context.go(AppRoutes.fleet);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete vehicle',
      message: 'This permanently removes the vehicle record.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result =
        await ref.read(vehicleDetailProvider(id).notifier).deleteVehicle(id);
    if (!context.mounted) {
      return;
    }

    if (result.error == null) {
      showSnackBarMessage(context, 'Vehicle deleted.');
      context.go(AppRoutes.fleet);
      return;
    }

    if (result.suggestRetire) {
      await showConflictDialog(
        context,
        message: result.error!,
        confirmLabel: 'Retire instead',
        onConfirm: () async {
          final result = await ref
              .read(vehicleDetailProvider(id).notifier)
              .retireVehicle(id);
          if (context.mounted) {
            if (result.error == null) {
              showSnackBarMessage(context, 'Vehicle retired.');
              context.go(AppRoutes.fleet);
            } else {
              showSnackBarMessage(context, result.error!);
            }
          }
        },
      );
    } else {
      showSnackBarMessage(context, result.error!);
    }
  }
}

class _VehicleActionsCard extends StatelessWidget {
  const _VehicleActionsCard({
    required this.isMutating,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onRetire,
    required this.onDelete,
  });

  final bool isMutating;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onRetire;
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
            label: 'Edit Vehicle',
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
            icon: Icons.archive_outlined,
            label: 'Retire Vehicle',
            enabled: !isMutating,
            iconColor: AppColors.warning,
            onTap: onRetire,
          ),
          Divider(height: 1, color: borderColor),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete Vehicle',
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
