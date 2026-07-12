class VehicleRoiRow {
  const VehicleRoiRow({
    required this.vehicleId,
    required this.registrationNumber,
    required this.name,
    required this.totalRevenue,
    required this.operationalCost,
    required this.acquisitionCost,
    required this.netProfit,
    required this.roi,
  });

  final String vehicleId;
  final String registrationNumber;
  final String name;
  final double totalRevenue;
  final double operationalCost;
  final double acquisitionCost;
  final double netProfit;
  final double? roi;

  factory VehicleRoiRow.fromJson(Map<String, dynamic> json) {
    return VehicleRoiRow(
      vehicleId: json['vehicleId'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalRevenue: _toDouble(json['totalRevenue']),
      operationalCost: _toDouble(json['operationalCost']),
      acquisitionCost: _toDouble(json['acquisitionCost']),
      netProfit: _toDouble(json['netProfit']),
      roi: _toDoubleOrNull(json['roi']),
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
