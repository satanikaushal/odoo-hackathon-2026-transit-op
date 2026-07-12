import '../../fleet/domain/fleet_formatters.dart';
import 'models/trip.dart';

abstract final class TripFormatters {
  static String formatRoute(Trip trip) => trip.routeLabel;

  static String formatWeight(double kg) => FleetFormatters.formatCapacity(kg);

  static String formatDistance(double km) => FleetFormatters.formatOdometer(km);

  static String formatRevenue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    return FleetFormatters.formatCurrency(raw);
  }

  static String formatFuel(double? liters) {
    if (liters == null) {
      return '—';
    }
    return '${liters.round()} L';
  }

  static String vehicleLabel(Trip trip) {
    final vehicle = trip.vehicle;
    if (vehicle == null) {
      return trip.vehicleId;
    }
    return '${vehicle.registrationNumber} · ${vehicle.name}';
  }

  static String driverLabel(Trip trip) {
    final driver = trip.driver;
    if (driver == null) {
      return trip.driverId;
    }
    return driver.name;
  }
}
