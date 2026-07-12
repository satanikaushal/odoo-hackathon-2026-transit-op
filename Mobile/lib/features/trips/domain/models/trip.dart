import 'trip_embed.dart';
import 'trip_status.dart';

class Trip {
  const Trip({
    required this.id,
    required this.source,
    required this.destination,
    required this.vehicleId,
    required this.driverId,
    required this.cargoWeight,
    required this.plannedDistance,
    required this.status,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.actualDistance,
    this.finalOdometer,
    this.fuelConsumed,
    this.revenue,
    this.dispatchedAt,
    this.completedAt,
    this.cancelledAt,
    this.vehicle,
    this.driver,
  });

  final String id;
  final String source;
  final String destination;
  final String vehicleId;
  final String driverId;
  final double cargoWeight;
  final double plannedDistance;
  final double? actualDistance;
  final double? finalOdometer;
  final double? fuelConsumed;
  final String? revenue;
  final TripStatus status;
  final String createdById;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripVehicleEmbed? vehicle;
  final TripDriverEmbed? driver;

  String get routeLabel => '$source → $destination';

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      cargoWeight: _toDouble(json['cargoWeight']),
      plannedDistance: _toDouble(json['plannedDistance']),
      actualDistance: _toDoubleOrNull(json['actualDistance']),
      finalOdometer: _toDoubleOrNull(json['finalOdometer']),
      fuelConsumed: _toDoubleOrNull(json['fuelConsumed']),
      revenue: json['revenue']?.toString(),
      status: TripStatus.fromString(json['status'] as String?) ??
          TripStatus.DRAFT,
      createdById: json['createdById'] as String? ?? '',
      dispatchedAt: _parseDateOrNull(json['dispatchedAt']),
      completedAt: _parseDateOrNull(json['completedAt']),
      cancelledAt: _parseDateOrNull(json['cancelledAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? TripVehicleEmbed.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? TripDriverEmbed.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
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
