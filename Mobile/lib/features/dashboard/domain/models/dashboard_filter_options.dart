class DashboardFilterOptions {
  const DashboardFilterOptions({
    required this.types,
    required this.regions,
    required this.statuses,
  });

  final List<String> types;
  final List<String> regions;
  final List<String> statuses;

  factory DashboardFilterOptions.fromJson(Map<String, dynamic> json) {
    return DashboardFilterOptions(
      types: _stringList(json['types']),
      regions: _stringList(json['regions']),
      statuses: _stringList(json['statuses']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }
}
