import 'expense.dart';
import 'paginated_fuel_logs.dart';

class PaginatedExpenses {
  const PaginatedExpenses({
    required this.items,
    required this.pagination,
  });

  final List<Expense> items;
  final PaginationMeta pagination;

  factory PaginatedExpenses.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PaginatedExpenses(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Expense.fromJson)
              .toList()
          : const [],
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory PaginatedExpenses.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return PaginatedExpenses.fromJson(data);
    }
    if (data is List) {
      final items =
          data.whereType<Map<String, dynamic>>().map(Expense.fromJson).toList();
      return PaginatedExpenses(
        items: items,
        pagination: PaginationMeta(
          page: 1,
          limit: items.length,
          total: items.length,
          totalPages: 1,
        ),
      );
    }
    return const PaginatedExpenses(
      items: [],
      pagination: PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }
}
