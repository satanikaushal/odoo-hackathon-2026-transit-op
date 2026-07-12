import '../../fleet/domain/fleet_formatters.dart';

abstract final class AnalyticsFormatters {
  static String formatCurrency(num value) {
    return FleetFormatters.formatCurrency(value.toString());
  }

  static String formatDistance(double km) {
    return FleetFormatters.formatOdometer(km);
  }

  static String formatLiters(double liters) {
    return '${liters.round()} L';
  }

  static String formatKmPerLiter(double? value) {
    if (value == null) {
      return '—';
    }
    return '${value.toStringAsFixed(2)} km/L';
  }

  static String formatPercent(double? value) {
    if (value == null) {
      return '—';
    }
    return '${value.toStringAsFixed(2)}%';
  }

  static String formatRoi(double? value) {
    if (value == null) {
      return '—';
    }
    return '${(value * 100).toStringAsFixed(2)}%';
  }
}
