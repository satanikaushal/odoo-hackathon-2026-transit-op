import 'maintenance_status.dart';
import 'maintenance_vehicle_embed.dart';

class MaintenanceLog {
  const MaintenanceLog({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.cost,
    required this.status,
    required this.openedAt,
    required this.createdAt,
    this.closedAt,
    this.vehicle,
  });

  final String id;
  final String vehicleId;
  final String description;
  final String cost;
  final MaintenanceStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final MaintenanceVehicleEmbed? vehicle;

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cost: json['cost']?.toString() ?? '0',
      status: MaintenanceStatus.fromString(json['status'] as String?) ??
          MaintenanceStatus.OPEN,
      openedAt: _parseDate(json['openedAt']),
      closedAt: _parseDateOrNull(json['closedAt']),
      createdAt: _parseDate(json['createdAt']),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? MaintenanceVehicleEmbed.fromJson(
              json['vehicle'] as Map<String, dynamic>,
            )
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
}
