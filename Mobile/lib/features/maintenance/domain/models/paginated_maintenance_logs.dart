import 'maintenance_log.dart';

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

class PaginatedMaintenanceLogs {
  const PaginatedMaintenanceLogs({
    required this.items,
    required this.pagination,
  });

  final List<MaintenanceLog> items;
  final PaginationMeta pagination;

  factory PaginatedMaintenanceLogs.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PaginatedMaintenanceLogs(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(MaintenanceLog.fromJson)
              .toList()
          : const [],
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// Supports legacy/plain-array responses if the backend shape differs.
  factory PaginatedMaintenanceLogs.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return PaginatedMaintenanceLogs.fromJson(data);
    }
    if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(MaintenanceLog.fromJson)
          .toList();
      return PaginatedMaintenanceLogs(
        items: items,
        pagination: PaginationMeta(
          page: 1,
          limit: items.length,
          total: items.length,
          totalPages: 1,
        ),
      );
    }
    return const PaginatedMaintenanceLogs(
      items: [],
      pagination: PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }
}
