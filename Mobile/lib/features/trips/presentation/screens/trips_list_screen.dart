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
import '../../application/trip_list_provider.dart';
import '../../domain/trip_permissions.dart';
import '../../domain/models/trip_status.dart';
import '../widgets/trip_data_table.dart';
import '../widgets/trip_filters_bar.dart';
import '../widgets/trip_list_card.dart';
import '../widgets/trip_list_shimmer.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
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
      ref.read(tripListProvider.notifier).loadMore();
    }
  }

  void _openCreateTrip() {
    context.push(AppRoutes.tripsAdd);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripListProvider);
    final notifier = ref.read(tripListProvider.notifier);
    final canManage =
        ref.watch(authSessionProvider).role?.canManageTrips ?? false;
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    Widget body;

    if (state.isInitialLoading && state.trips.isEmpty) {
      body = ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [TripListShimmer()],
      );
    } else if (state.error != null &&
        state.trips.isEmpty &&
        !state.isRefreshingList) {
      body = _TripsErrorView(
        message: state.error!,
        onRetry: notifier.refresh,
      );
    } else {
      body = ListView(
        controller: _scrollController,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          TripFiltersBar(
            statusOptions: TripStatus.values,
            selectedStatus: state.selectedStatus,
            searchController: _searchController,
            onStatusChanged: notifier.setStatus,
            onSearchChanged: notifier.setSearchQuery,
          ),
          const AppGap(16),
          if (state.isRefreshingList)
            const TripListItemsShimmer()
          else if (state.trips.isEmpty)
            const _TripsEmptyView()
          else if (useTable)
            TripDataTable(trips: state.trips)
          else
            ...state.trips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TripListCard(trip: trip),
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
              onPressed: _openCreateTrip,
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
            )
          : null,
    );
  }
}

class _TripsEmptyView extends StatelessWidget {
  const _TripsEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          'No trips found',
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TripsErrorView extends StatelessWidget {
  const _TripsErrorView({
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
