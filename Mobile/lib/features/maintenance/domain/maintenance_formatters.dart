import '../../fleet/domain/fleet_formatters.dart';
import 'models/maintenance_log.dart';

abstract final class MaintenanceFormatters {
  static String formatCost(String raw) => FleetFormatters.formatCurrency(raw);

  static String vehicleLabel(MaintenanceLog log) {
    final vehicle = log.vehicle;
    if (vehicle == null) {
      return log.vehicleId;
    }
    return '${vehicle.registrationNumber} · ${vehicle.name}';
  }

  static String formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
