import 'package:intl/intl.dart';

abstract final class FleetFormatters {
  static final _indianNumber = NumberFormat('#,##,###', 'en_IN');
  static final _odometer = NumberFormat('#,##,###', 'en_IN');

  static String formatCurrency(String rawValue) {
    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }
    return '₹${_indianNumber.format(parsed.round())}';
  }

  static String formatOdometer(double value) {
    return '${_odometer.format(value.round())} km';
  }

  static String formatCapacity(double kg) {
    if (kg >= 1000) {
      final tons = kg / 1000;
      if (tons == tons.roundToDouble()) {
        return '${tons.round()} Ton';
      }
      return '${tons.toStringAsFixed(1)} Ton';
    }
    return '${kg.round()} kg';
  }
}
