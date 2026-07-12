class FleetUtilizationReport {
  const FleetUtilizationReport({
    required this.onTripVehicles,
    required this.nonRetiredVehicles,
    required this.totalVehicles,
    required this.utilizationPct,
  });

  final int onTripVehicles;
  final int nonRetiredVehicles;
  final int totalVehicles;
  final double? utilizationPct;

  factory FleetUtilizationReport.fromJson(Map<String, dynamic> json) {
    return FleetUtilizationReport(
      onTripVehicles: _toInt(json['onTripVehicles']),
      nonRetiredVehicles: _toInt(json['nonRetiredVehicles']),
      totalVehicles: _toInt(json['totalVehicles']),
      utilizationPct: _toDoubleOrNull(json['utilizationPct']),
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
