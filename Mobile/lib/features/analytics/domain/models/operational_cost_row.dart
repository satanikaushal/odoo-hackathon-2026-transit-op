class OperationalCostRow {
  const OperationalCostRow({
    required this.vehicleId,
    required this.registrationNumber,
    required this.name,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.operationalCost,
  });

  final String vehicleId;
  final String registrationNumber;
  final String name;
  final double fuelCost;
  final double maintenanceCost;
  final double operationalCost;

  factory OperationalCostRow.fromJson(Map<String, dynamic> json) {
    return OperationalCostRow(
      vehicleId: json['vehicleId'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fuelCost: _toDouble(json['fuelCost']),
      maintenanceCost: _toDouble(json['maintenanceCost']),
      operationalCost: _toDouble(json['operationalCost']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
