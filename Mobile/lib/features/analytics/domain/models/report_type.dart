enum ReportType {
  fuelEfficiency,
  fleetUtilization,
  operationalCost,
  vehicleRoi;

  String get label {
    return switch (this) {
      ReportType.fuelEfficiency => 'Fuel Efficiency',
      ReportType.fleetUtilization => 'Fleet Utilization',
      ReportType.operationalCost => 'Operational Cost',
      ReportType.vehicleRoi => 'Vehicle ROI',
    };
  }

  String get exportSlug {
    return switch (this) {
      ReportType.fuelEfficiency => 'fuel-efficiency',
      ReportType.fleetUtilization => 'fleet-utilization',
      ReportType.operationalCost => 'operational-cost',
      ReportType.vehicleRoi => 'vehicle-roi',
    };
  }
}
