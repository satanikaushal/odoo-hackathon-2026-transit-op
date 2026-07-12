import 'driver_status.dart';

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.licenseCategory,
    required this.licenseExpiryDate,
    required this.contactNumber,
    required this.safetyScore,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String licenseNumber;
  final String licenseCategory;
  final DateTime licenseExpiryDate;
  final String contactNumber;
  final double safetyScore;
  final DriverStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLicenseExpired {
    final today = DateTime.now();
    final expiry = DateTime(
      licenseExpiryDate.year,
      licenseExpiryDate.month,
      licenseExpiryDate.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return expiry.isBefore(todayDate);
  }

  static String formatDateForApi(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseCategory: json['licenseCategory'] as String? ?? '',
      licenseExpiryDate: _parseDate(json['licenseExpiryDate']),
      contactNumber: json['contactNumber'] as String? ?? '',
      safetyScore: _toDouble(json['safetyScore']),
      status: DriverStatus.fromString(json['status'] as String?) ??
          DriverStatus.AVAILABLE,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'licenseNumber': licenseNumber,
      'licenseCategory': licenseCategory,
      'licenseExpiryDate': formatDateForApi(licenseExpiryDate),
      'contactNumber': contactNumber,
      'safetyScore': safetyScore,
      'status': status.name,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 100;
  }
}
