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
import '../../../../shared/widgets/refreshable_list.dart';
import '../../application/driver_list_provider.dart';
import '../../domain/driver_permissions.dart';
import '../../domain/models/driver_status.dart';
import '../widgets/driver_data_table.dart';
import '../widgets/driver_filters_bar.dart';
import '../widgets/driver_list_card.dart';
import '../widgets/driver_list_shimmer.dart';

class DriversListScreen extends ConsumerStatefulWidget {
  const DriversListScreen({super.key});

  @override
  ConsumerState<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends ConsumerState<DriversListScreen> {
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
      ref.read(driverListProvider.notifier).loadMore();
    }
  }

  void _openAddDriver() {
    context.push(AppRoutes.driversAdd);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverListProvider);
    final notifier = ref.read(driverListProvider.notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageDrivers ?? false;
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    Widget body;

    if (state.isInitialLoading && state.drivers.isEmpty) {
      body = RefreshableList.scroll(
        onRefresh: notifier.refresh,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [DriverListShimmer()],
      );
    } else if (state.error != null &&
        state.drivers.isEmpty &&
        !state.isRefreshingList) {
      body = RefreshableList.centered(
        onRefresh: notifier.refresh,
        child: _DriversErrorView(
          message: state.error!,
          onRetry: notifier.refresh,
        ),
      );
    } else {
      body = RefreshableList.scroll(
        onRefresh: notifier.refresh,
        controller: _scrollController,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          DriverFiltersBar(
            statusOptions: DriverStatus.values,
            selectedStatus: state.selectedStatus,
            searchController: _searchController,
            onStatusChanged: notifier.setStatus,
            onSearchChanged: notifier.setSearchQuery,
          ),
          const AppGap(16),
          if (state.isRefreshingList)
            const DriverListItemsShimmer()
          else if (state.drivers.isEmpty)
            const _DriversEmptyView()
          else if (useTable)
            DriverDataTable(drivers: state.drivers)
          else
            ...state.drivers.map(
              (driver) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DriverListCard(driver: driver),
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
              onPressed: _openAddDriver,
              icon: const Icon(Icons.add),
              label: const Text('Add Driver'),
            )
          : null,
    );
  }
}

class _DriversEmptyView extends StatelessWidget {
  const _DriversEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          'No drivers found',
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DriversErrorView extends StatelessWidget {
  const _DriversErrorView({
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
