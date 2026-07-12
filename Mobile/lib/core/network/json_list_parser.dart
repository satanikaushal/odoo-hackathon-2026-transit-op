/// Parses list payloads whether the API returns a bare array or `{ items: [] }`.
List<T> parseJsonList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
  if (data is Map<String, dynamic>) {
    final items = data['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }
  }
  return const [];
}
