import 'vehicle.dart';

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

class PaginatedVehicles {
  const PaginatedVehicles({
    required this.items,
    required this.pagination,
  });

  final List<Vehicle> items;
  final PaginationMeta pagination;

  factory PaginatedVehicles.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PaginatedVehicles(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Vehicle.fromJson)
              .toList()
          : const [],
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
