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
import '../../application/expense_list_provider.dart';
import '../../application/fuel_log_list_provider.dart';
import '../../domain/expenses_permissions.dart';
import '../widgets/expense_data_table.dart';
import '../widgets/expense_list_card.dart';
import '../widgets/expenses_filters_bar.dart';
import '../widgets/expenses_list_shimmer.dart';
import '../widgets/fuel_log_data_table.dart';
import '../widgets/fuel_log_list_card.dart';

class ExpensesHubScreen extends ConsumerStatefulWidget {
  const ExpensesHubScreen({super.key});

  @override
  ConsumerState<ExpensesHubScreen> createState() => _ExpensesHubScreenState();
}

class _ExpensesHubScreenState extends ConsumerState<ExpensesHubScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _fuelScrollController = ScrollController();
  final _expenseScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fuelScrollController.addListener(_onFuelScroll);
    _expenseScrollController.addListener(_onExpenseScroll);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _fuelScrollController.dispose();
    _expenseScrollController.dispose();
    super.dispose();
  }

  void _onFuelScroll() {
    _maybeLoadMore(_fuelScrollController, () {
      ref.read(fuelLogListProvider.notifier).loadMore();
    });
  }

  void _onExpenseScroll() {
    _maybeLoadMore(_expenseScrollController, () {
      ref.read(expenseListProvider.notifier).loadMore();
    });
  }

  void _maybeLoadMore(ScrollController controller, VoidCallback loadMore) {
    if (!controller.hasClients) {
      return;
    }
    final threshold = controller.position.maxScrollExtent - 200;
    if (controller.position.pixels >= threshold) {
      loadMore();
    }
  }

  TabController _ensureTabController(bool showBothTabs) {
    final length = showBothTabs ? 2 : 1;
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
    return _tabController!;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authSessionProvider).role;
    final canReadFuel = role?.canReadFuelLogs ?? false;
    final canReadExpenses = role?.canReadExpenses ?? false;
    final canCreateFuel = role?.canCreateFuelLogs ?? false;
    final canCreateExpenses = role?.canCreateExpenses ?? false;
    final showBothTabs = canReadFuel && canReadExpenses;

    if (!canReadFuel && !canReadExpenses) {
      return const Center(
        child: AppText(
          'You do not have access to this section.',
          size: 14,
        ),
      );
    }

    final tabController = _ensureTabController(showBothTabs);
    final useTable =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBothTabs)
            TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: 'Fuel Logs'),
                Tab(text: 'Expenses'),
              ],
            ),
          Expanded(
            child: showBothTabs
                ? TabBarView(
                    controller: tabController,
                    children: [
                      _FuelLogsTab(
                        scrollController: _fuelScrollController,
                        useTable: useTable,
                      ),
                      _ExpensesTab(
                        scrollController: _expenseScrollController,
                        useTable: useTable,
                      ),
                    ],
                  )
                : canReadFuel
                    ? _FuelLogsTab(
                        scrollController: _fuelScrollController,
                        useTable: useTable,
                      )
                    : _ExpensesTab(
                        scrollController: _expenseScrollController,
                        useTable: useTable,
                      ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(
        showBothTabs: showBothTabs,
        tabController: tabController,
        canCreateFuel: canCreateFuel,
        canCreateExpenses: canCreateExpenses,
        canReadFuel: canReadFuel,
      ),
    );
  }

  Widget? _buildFab({
    required bool showBothTabs,
    required TabController tabController,
    required bool canCreateFuel,
    required bool canCreateExpenses,
    required bool canReadFuel,
  }) {
    if (showBothTabs) {
      return AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          if (tabController.index == 0 && canCreateFuel) {
            return FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.fuelLogAdd),
              icon: const Icon(Icons.add),
              label: const Text('Log Fuel'),
            );
          }
          if (tabController.index == 1 && canCreateExpenses) {
            return FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.expenseRecordAdd),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    if (canReadFuel && canCreateFuel) {
      return FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.fuelLogAdd),
        icon: const Icon(Icons.add),
        label: const Text('Log Fuel'),
      );
    }

    if (!canReadFuel && canCreateExpenses) {
      return FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.expenseRecordAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      );
    }

    return null;
  }
}

class _FuelLogsTab extends ConsumerWidget {
  const _FuelLogsTab({
    required this.scrollController,
    required this.useTable,
  });

  final ScrollController scrollController;
  final bool useTable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogListProvider);
    final notifier = ref.read(fuelLogListProvider.notifier);

    if (state.isInitialLoading && state.logs.isEmpty) {
      return RefreshableList.scroll(
        onRefresh: notifier.refresh,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [ExpensesListShimmer()],
      );
    }

    if (state.error != null &&
        state.logs.isEmpty &&
        !state.isRefreshingList) {
      return RefreshableList.centered(
        onRefresh: notifier.refresh,
        child: _ErrorView(message: state.error!, onRetry: notifier.refresh),
      );
    }

    return RefreshableList.scroll(
      onRefresh: notifier.refresh,
      controller: scrollController,
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        if (state.isRefreshingList)
          const ExpensesListItemsShimmer()
        else if (state.logs.isEmpty)
          const _EmptyView(message: 'No fuel logs found')
        else if (useTable)
          FuelLogDataTable(logs: state.logs)
        else
          ...state.logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FuelLogListCard(log: log),
            ),
          ),
        if (state.isLoadingMore) ...[
          const AppGap(12),
          const AppShimmerListFooter(itemCount: 2, itemHeight: 88),
        ],
        const AppGap(80),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({
    required this.scrollController,
    required this.useTable,
  });

  final ScrollController scrollController;
  final bool useTable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseListProvider);
    final notifier = ref.read(expenseListProvider.notifier);

    if (state.isInitialLoading && state.expenses.isEmpty) {
      return RefreshableList.scroll(
        onRefresh: notifier.refresh,
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: const [ExpensesListShimmer()],
      );
    }

    if (state.error != null &&
        state.expenses.isEmpty &&
        !state.isRefreshingList) {
      return RefreshableList.centered(
        onRefresh: notifier.refresh,
        child: _ErrorView(message: state.error!, onRetry: notifier.refresh),
      );
    }

    return RefreshableList.scroll(
      onRefresh: notifier.refresh,
      controller: scrollController,
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        ExpensesFiltersBar(
          selectedCategory: state.selectedCategory,
          onCategoryChanged: notifier.setCategory,
        ),
        const AppGap(16),
        if (state.isRefreshingList)
          const ExpensesListItemsShimmer()
        else if (state.expenses.isEmpty)
          const _EmptyView(message: 'No expenses found')
        else if (useTable)
          ExpenseDataTable(expenses: state.expenses)
        else
          ...state.expenses.map(
            (expense) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpenseListCard(expense: expense),
            ),
          ),
        if (state.isLoadingMore) ...[
          const AppGap(12),
          const AppShimmerListFooter(itemCount: 2, itemHeight: 88),
        ],
        const AppGap(80),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: AppText(
          message,
          size: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
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
