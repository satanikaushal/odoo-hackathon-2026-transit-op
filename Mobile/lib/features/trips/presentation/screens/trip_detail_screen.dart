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
import '../../application/trip_detail_provider.dart';
import '../../domain/models/trip_status.dart';
import '../../domain/trip_formatters.dart';
import '../../domain/trip_permissions.dart';
import '../widgets/trip_status_badge.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripDetailProvider(tripId));
    final notifier = ref.read(tripDetailProvider(tripId).notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageTrips ?? false;

    if (state.isLoading && state.trip == null) {
      return ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          AppShimmer(
            child: AppShimmerBox(
              height: Responsive.getH(320),
              borderRadius: 12,
            ),
          ),
        ],
      );
    }

    if (state.error != null && state.trip == null) {
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
                onPressed: () => notifier.load(tripId),
              ),
            ],
          ),
        ),
      );
    }

    final trip = state.trip!;
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
                      trip.routeLabel,
                      size: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TripStatusBadge(status: trip.status),
                ],
              ),
              const AppGap(16),
              _DetailRow(label: 'Vehicle', value: TripFormatters.vehicleLabel(trip)),
              _DetailRow(label: 'Driver', value: TripFormatters.driverLabel(trip)),
              _DetailRow(
                label: 'Cargo Weight',
                value: TripFormatters.formatWeight(trip.cargoWeight),
              ),
              _DetailRow(
                label: 'Planned Distance',
                value: TripFormatters.formatDistance(trip.plannedDistance),
              ),
              if (trip.actualDistance != null)
                _DetailRow(
                  label: 'Actual Distance',
                  value: TripFormatters.formatDistance(trip.actualDistance!),
                ),
              if (trip.finalOdometer != null)
                _DetailRow(
                  label: 'Final Odometer',
                  value: TripFormatters.formatDistance(trip.finalOdometer!),
                ),
              if (trip.fuelConsumed != null)
                _DetailRow(
                  label: 'Fuel Consumed',
                  value: TripFormatters.formatFuel(trip.fuelConsumed),
                ),
              if (trip.revenue != null)
                _DetailRow(
                  label: 'Revenue',
                  value: TripFormatters.formatRevenue(trip.revenue),
                ),
              if (trip.dispatchedAt != null)
                _DetailRow(
                  label: 'Dispatched At',
                  value: _formatTimestamp(trip.dispatchedAt!),
                ),
              if (trip.completedAt != null)
                _DetailRow(
                  label: 'Completed At',
                  value: _formatTimestamp(trip.completedAt!),
                ),
              if (trip.cancelledAt != null)
                _DetailRow(
                  label: 'Cancelled At',
                  value: _formatTimestamp(trip.cancelledAt!),
                ),
            ],
          ),
        ),
        if (canManage && _hasActions(trip.status)) ...[
          const AppGap(20),
          _TripActionsCard(
            status: trip.status,
            isMutating: state.isMutating,
            onDispatch: () => _dispatch(context, ref, tripId),
            onComplete: () => context.push(AppRoutes.tripComplete(tripId)),
            onCancel: () => _cancel(context, ref, tripId),
          ),
        ],
        const AppGap(16),
      ],
    );
  }

  bool _hasActions(TripStatus status) {
    return status == TripStatus.DRAFT ||
        status == TripStatus.DISPATCHED;
  }

  String _formatTimestamp(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _dispatch(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Dispatch trip',
      message:
          'This assigns the vehicle and driver to this trip and sets both to On Trip.',
      confirmLabel: 'Dispatch',
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result =
        await ref.read(tripDetailProvider(id).notifier).dispatch(id);
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

    showSnackBarMessage(context, 'Trip dispatched.');
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel trip',
      message: 'This cancels the trip. Dispatched trips release the vehicle and driver.',
      confirmLabel: 'Cancel Trip',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final result = await ref.read(tripDetailProvider(id).notifier).cancel(id);
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

    showSnackBarMessage(context, 'Trip cancelled.');
  }
}

class _TripActionsCard extends StatelessWidget {
  const _TripActionsCard({
    required this.status,
    required this.isMutating,
    required this.onDispatch,
    required this.onComplete,
    required this.onCancel,
  });

  final TripStatus status;
  final bool isMutating;
  final VoidCallback onDispatch;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

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
          if (status == TripStatus.DRAFT) ...[
            _ActionTile(
              icon: Icons.local_shipping_outlined,
              label: 'Dispatch Trip',
              enabled: !isMutating,
              onTap: onDispatch,
            ),
            Divider(height: 1, color: borderColor),
          ],
          if (status == TripStatus.DISPATCHED) ...[
            _ActionTile(
              icon: Icons.check_circle_outline,
              label: 'Complete Trip',
              enabled: !isMutating,
              onTap: onComplete,
            ),
            Divider(height: 1, color: borderColor),
          ],
          _ActionTile(
            icon: Icons.cancel_outlined,
            label: 'Cancel Trip',
            enabled: !isMutating,
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: onCancel,
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
