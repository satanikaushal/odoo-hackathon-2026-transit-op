class FuelEfficiencyRow {
  const FuelEfficiencyRow({
    required this.vehicleId,
    required this.registrationNumber,
    required this.name,
    required this.totalDistance,
    required this.totalLiters,
    required this.kmPerLiter,
  });

  final String vehicleId;
  final String registrationNumber;
  final String name;
  final double totalDistance;
  final double totalLiters;
  final double? kmPerLiter;

  factory FuelEfficiencyRow.fromJson(Map<String, dynamic> json) {
    return FuelEfficiencyRow(
      vehicleId: json['vehicleId'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalDistance: _toDouble(json['totalDistance']),
      totalLiters: _toDouble(json['totalLiters']),
      kmPerLiter: _toDoubleOrNull(json['kmPerLiter']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
