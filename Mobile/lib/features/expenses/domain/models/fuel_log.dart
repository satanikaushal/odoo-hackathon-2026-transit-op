import 'cost_vehicle_embed.dart';

class FuelLog {
  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.liters,
    required this.cost,
    required this.date,
    required this.createdAt,
    this.tripId,
    this.vehicle,
  });

  final String id;
  final String vehicleId;
  final String? tripId;
  final double liters;
  final String cost;
  final DateTime date;
  final DateTime createdAt;
  final CostVehicleEmbed? vehicle;

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      tripId: json['tripId'] as String?,
      liters: _toDouble(json['liters']),
      cost: json['cost']?.toString() ?? '0',
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? CostVehicleEmbed.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
