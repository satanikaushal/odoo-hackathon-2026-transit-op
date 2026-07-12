import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/expense.dart';
import 'expenses_repository_provider.dart';

class ExpenseListState {
  const ExpenseListState({
    this.expenses = const [],
    this.selectedCategory,
    this.isInitialLoading = false,
    this.isRefreshingList = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  static const _unset = Object();

  final List<Expense> expenses;
  final String? selectedCategory;
  final bool isInitialLoading;
  final bool isRefreshingList;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  ExpenseListState copyWith({
    List<Expense>? expenses,
    Object? selectedCategory = _unset,
    bool? isInitialLoading,
    bool? isRefreshingList,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool clearError = false,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      selectedCategory: identical(selectedCategory, _unset)
          ? this.selectedCategory
          : selectedCategory as String?,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ExpenseListNotifier extends AutoDisposeNotifier<ExpenseListState> {
  @override
  ExpenseListState build() {
    ref.listen<int>(expenseListRefreshSignalProvider, (_, next) {
      refresh();
    });

    Future.microtask(_loadInitial);
    return const ExpenseListState(isInitialLoading: true);
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      expenses: [],
      currentPage: 0,
      hasMore: true,
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshingList ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.error != null) {
      return;
    }
    await _fetchPage(page: state.currentPage + 1, append: true);
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else if (state.expenses.isEmpty) {
      state = state.copyWith(isInitialLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshingList: true, clearError: true);
    }

    final result = await ref.read(expensesRepositoryProvider).fetchExpenses(
          page: page,
          category: state.selectedCategory,
        );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshingList: false,
        isLoadingMore: false,
        error: result.failure?.message ?? 'Unable to load expenses.',
      );
      return;
    }

    final data = result.data!;
    final merged = append ? [...state.expenses, ...data.items] : data.items;

    state = state.copyWith(
      expenses: merged,
      isInitialLoading: false,
      isRefreshingList: false,
      isLoadingMore: false,
      hasMore: data.pagination.hasNextPage,
      currentPage: data.pagination.page,
      clearError: true,
    );
  }

  void setCategory(String? category) {
    if (state.selectedCategory == category) {
      return;
    }
    state = state.copyWith(selectedCategory: category);
    _reloadFromFirstPage();
  }

  Future<void> _reloadFromFirstPage() async {
    state = state.copyWith(
      currentPage: 0,
      hasMore: true,
      clearError: true,
    );
    await _fetchPage(page: 1, append: false);
  }
}

final expenseListProvider =
    AutoDisposeNotifierProvider<ExpenseListNotifier, ExpenseListState>(
  ExpenseListNotifier.new,
);
