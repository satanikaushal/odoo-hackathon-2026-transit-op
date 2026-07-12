import 'trip.dart';

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

class PaginatedTrips {
  const PaginatedTrips({
    required this.items,
    required this.pagination,
  });

  final List<Trip> items;
  final PaginationMeta pagination;

  factory PaginatedTrips.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PaginatedTrips(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Trip.fromJson)
              .toList()
          : const [],
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
