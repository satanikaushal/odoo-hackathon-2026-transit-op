class DashboardKpis {
  const DashboardKpis({
    required this.activeVehicles,
    required this.availableVehicles,
    required this.vehiclesInMaintenance,
    required this.activeTrips,
    required this.pendingTrips,
    required this.driversOnDuty,
    required this.fleetUtilization,
  });

  final int activeVehicles;
  final int availableVehicles;
  final int vehiclesInMaintenance;
  final int activeTrips;
  final int pendingTrips;
  final int driversOnDuty;
  final double fleetUtilization;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      activeVehicles: _toInt(json['activeVehicles']),
      availableVehicles: _toInt(json['availableVehicles']),
      vehiclesInMaintenance: _toInt(json['vehiclesInMaintenance']),
      activeTrips: _toInt(json['activeTrips']),
      pendingTrips: _toInt(json['pendingTrips']),
      driversOnDuty: _toInt(json['driversOnDuty']),
      fleetUtilization: _toDouble(json['fleetUtilization']),
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

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
