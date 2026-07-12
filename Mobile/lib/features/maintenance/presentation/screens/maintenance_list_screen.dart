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
import '../../application/maintenance_list_provider.dart';
import '../../domain/maintenance_permissions.dart';
import '../../domain/models/maintenance_status.dart';
import '../widgets/maintenance_data_table.dart';
import '../widgets/maintenance_filters_bar.dart';
import '../widgets/maintenance_list_card.dart';
import '../widgets/maintenance_list_shimmer.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(maintenanceListProvider.notifier).loadMore();
    }
  }

  void _openMaintenanceForm() {
    context.push(AppRoutes.maintenanceAdd);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceListProvider);
    final notifier = ref.read(maintenanceListProvider.notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageMaintenance ?? false;
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    Widget body;

    if (state.isInitialLoading && state.logs.isEmpty) {
      body = RefreshableList.scroll(
        onRefresh: notifier.refresh,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [MaintenanceListShimmer()],
      );
    } else if (state.error != null &&
        state.logs.isEmpty &&
        !state.isRefreshingList) {
      body = RefreshableList.centered(
        onRefresh: notifier.refresh,
        child: _MaintenanceErrorView(
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
          MaintenanceFiltersBar(
            statusOptions: MaintenanceStatus.values,
            selectedStatus: state.selectedStatus,
            onStatusChanged: notifier.setStatus,
          ),
          const AppGap(16),
          if (state.isRefreshingList)
            const MaintenanceListItemsShimmer()
          else if (state.logs.isEmpty)
            const _MaintenanceEmptyView()
          else if (useTable)
            MaintenanceDataTable(logs: state.logs)
          else
            ...state.logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MaintenanceListCard(log: log),
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
              onPressed: _openMaintenanceForm,
              icon: const Icon(Icons.add),
              label: const Text('Open Maintenance'),
            )
          : null,
    );
  }
}

class _MaintenanceEmptyView extends StatelessWidget {
  const _MaintenanceEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          'No maintenance records found',
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MaintenanceErrorView extends StatelessWidget {
  const _MaintenanceErrorView({
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
