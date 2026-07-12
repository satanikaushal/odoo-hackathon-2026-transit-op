import 'fuel_log.dart';

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      totalPages: _toInt(json['totalPages']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}

class PaginatedFuelLogs {
  const PaginatedFuelLogs({
    required this.items,
    required this.pagination,
  });

  final List<FuelLog> items;
  final PaginationMeta pagination;

  factory PaginatedFuelLogs.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PaginatedFuelLogs(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(FuelLog.fromJson)
              .toList()
          : const [],
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory PaginatedFuelLogs.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return PaginatedFuelLogs.fromJson(data);
    }
    if (data is List) {
      final items =
          data.whereType<Map<String, dynamic>>().map(FuelLog.fromJson).toList();
      return PaginatedFuelLogs(
        items: items,
        pagination: PaginationMeta(
          page: 1,
          limit: items.length,
          total: items.length,
          totalPages: 1,
        ),
      );
    }
    return const PaginatedFuelLogs(
      items: [],
      pagination: PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }
}
