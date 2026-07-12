import 'vehicle_status.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.name,
    required this.type,
    required this.maxLoadCapacity,
    required this.odometer,
    required this.acquisitionCost,
    required this.status,
    this.region,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String registrationNumber;
  final String name;
  final String type;
  final double maxLoadCapacity;
  final double odometer;
  final String acquisitionCost;
  final VehicleStatus status;
  final String? region;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      maxLoadCapacity: _toDouble(json['maxLoadCapacity']),
      odometer: _toDouble(json['odometer']),
      acquisitionCost: json['acquisitionCost']?.toString() ?? '0',
      status: VehicleStatus.fromString(json['status'] as String?) ??
          VehicleStatus.AVAILABLE,
      region: json['region'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'registrationNumber': registrationNumber,
      'name': name,
      'type': type,
      'maxLoadCapacity': maxLoadCapacity,
      'odometer': odometer,
      'acquisitionCost': acquisitionCost,
      if (region != null && region!.isNotEmpty) 'region': region,
      'status': status.name,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'registrationNumber': registrationNumber,
      'name': name,
      'type': type,
      'maxLoadCapacity': maxLoadCapacity,
      'odometer': odometer,
      'acquisitionCost': acquisitionCost,
      'region': region,
      'status': status.name,
    };
  }

  Vehicle copyWith({
    String? registrationNumber,
    String? name,
    String? type,
    double? maxLoadCapacity,
    double? odometer,
    String? acquisitionCost,
    VehicleStatus? status,
    String? region,
  }) {
    return Vehicle(
      id: id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      name: name ?? this.name,
      type: type ?? this.type,
      maxLoadCapacity: maxLoadCapacity ?? this.maxLoadCapacity,
      odometer: odometer ?? this.odometer,
      acquisitionCost: acquisitionCost ?? this.acquisitionCost,
      status: status ?? this.status,
      region: region ?? this.region,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
