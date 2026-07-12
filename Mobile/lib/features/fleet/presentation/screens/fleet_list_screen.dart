import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_session_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/shell_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../application/fleet_list_provider.dart';
import '../../domain/fleet_permissions.dart';
import '../../domain/models/vehicle_status.dart';
import '../widgets/fleet_filters_bar.dart';
import '../widgets/fleet_list_shimmer.dart';
import '../widgets/vehicle_data_table.dart';
import '../widgets/vehicle_list_card.dart';

class FleetListScreen extends ConsumerStatefulWidget {
  const FleetListScreen({super.key});

  @override
  ConsumerState<FleetListScreen> createState() => _FleetListScreenState();
}

class _FleetListScreenState extends ConsumerState<FleetListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(fleetListProvider.notifier).loadMore();
    }
  }

  void _openAddVehicle() {
    context.push(AppRoutes.fleetAdd);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fleetListProvider);
    final notifier = ref.read(fleetListProvider.notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageFleet ?? false;
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    Widget body;

    if (state.isInitialLoading && state.vehicles.isEmpty) {
      body = ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [FleetListShimmer()],
      );
    } else if (state.error != null && state.vehicles.isEmpty && !state.isRefreshingList) {
      body = _FleetErrorView(
        message: state.error!,
        onRetry: notifier.refresh,
      );
    } else {
      body = ListView(
        controller: _scrollController,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          FleetFiltersBar(
            typeOptions: state.typeOptions,
            statusOptions: VehicleStatus.values,
            selectedType: state.selectedType,
            selectedStatus: state.selectedStatus,
            searchController: _searchController,
            onTypeChanged: notifier.setType,
            onStatusChanged: notifier.setStatus,
          onSearchChanged: notifier.setSearchQuery,
        ),
        const AppGap(16),
        if (state.isRefreshingList)
          const FleetListItemsShimmer()
        else if (state.vehicles.isEmpty)
          const _FleetEmptyView()
        else if (useTable)
          VehicleDataTable(vehicles: state.vehicles)
        else
          ...state.vehicles.map(
              (vehicle) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VehicleListCard(vehicle: vehicle),
              ),
            ),
          if (state.isLoadingMore) ...[
            const AppGap(12),
            const AppShimmerListFooter(itemCount: 2, itemHeight: 88),
          ],
          const AppGap(12),
          const AppGap(80),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
    );
  }
}

class _FleetEmptyView extends StatelessWidget {
  const _FleetEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          'No vehicles found',
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FleetErrorView extends StatelessWidget {
  const _FleetErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        child: Container(
          width: double.infinity,
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(Responsive.getR(12)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                message,
                size: 14,
                textAlign: TextAlign.center,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                onPressed: onRetry,
                expand: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
