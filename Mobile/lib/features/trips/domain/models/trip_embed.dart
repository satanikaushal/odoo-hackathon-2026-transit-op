class TripVehicleEmbed {
  const TripVehicleEmbed({
    required this.id,
    required this.registrationNumber,
    required this.name,
    required this.status,
    this.odometer,
    this.maxLoadCapacity,
  });

  final String id;
  final String registrationNumber;
  final String name;
  final String status;
  final double? odometer;
  final double? maxLoadCapacity;

  factory TripVehicleEmbed.fromJson(Map<String, dynamic> json) {
    return TripVehicleEmbed(
      id: json['id'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      odometer: _toDoubleOrNull(json['odometer']),
      maxLoadCapacity: _toDoubleOrNull(json['maxLoadCapacity']),
    );
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

class TripDriverEmbed {
  const TripDriverEmbed({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.status,
  });

  final String id;
  final String name;
  final String licenseNumber;
  final String status;

  factory TripDriverEmbed.fromJson(Map<String, dynamic> json) {
    return TripDriverEmbed(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
