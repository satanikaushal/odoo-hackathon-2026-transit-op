class VehicleOperationalCost {
  const VehicleOperationalCost({
    required this.vehicleId,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.operationalCost,
  });

  final String vehicleId;
  final String fuelCost;
  final String maintenanceCost;
  final String operationalCost;

  factory VehicleOperationalCost.fromJson(Map<String, dynamic> json) {
    return VehicleOperationalCost(
      vehicleId: json['vehicleId'] as String? ?? '',
      fuelCost: _money(json['fuelCost']),
      maintenanceCost: _money(json['maintenanceCost']),
      operationalCost: _money(json['operationalCost']),
    );
  }

  static String _money(dynamic value) {
    if (value == null) {
      return '0';
    }
    return value.toString();
  }
}
