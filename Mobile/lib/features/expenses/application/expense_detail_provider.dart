import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/expense.dart';
import 'expenses_repository_provider.dart';

class ExpenseDetailState {
  const ExpenseDetailState({
    this.expense,
    this.isLoading = false,
    this.error,
  });

  final Expense? expense;
  final bool isLoading;
  final String? error;

  ExpenseDetailState copyWith({
    Expense? expense,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExpenseDetailState(
      expense: expense ?? this.expense,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpenseDetailNotifier
    extends AutoDisposeFamilyNotifier<ExpenseDetailState, String> {
  @override
  ExpenseDetailState build(String id) {
    ref.listen<int>(expenseListRefreshSignalProvider, (_, next) {
      load(id);
    });

    Future.microtask(() => load(id));
    return const ExpenseDetailState(isLoading: true);
  }

  Future<void> load(String id) async {
    if (state.expense == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    final result = await ref.read(expensesRepositoryProvider).fetchExpense(id);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Expense not found.',
      );
      return;
    }

    state = state.copyWith(
      expense: result.data,
      isLoading: false,
      clearError: true,
    );
  }
}

final expenseDetailProvider = AutoDisposeNotifierProviderFamily<
    ExpenseDetailNotifier, ExpenseDetailState, String>(
  ExpenseDetailNotifier.new,
);
