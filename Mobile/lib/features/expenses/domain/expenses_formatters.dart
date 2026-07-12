import '../../fleet/domain/fleet_formatters.dart';
import 'models/cost_vehicle_embed.dart';
import 'models/expense.dart';
import 'models/fuel_log.dart';

abstract final class ExpensesFormatters {
  static String formatMoney(String raw) => FleetFormatters.formatCurrency(raw);

  static String formatLiters(double liters) {
    if (liters == liters.roundToDouble()) {
      return '${liters.round()} L';
    }
    return '${liters.toStringAsFixed(1)} L';
  }

  static String vehicleLabel(FuelLog log) =>
      _vehicleLabel(log.vehicle, log.vehicleId);

  static String vehicleLabelForExpense(Expense expense) =>
      _vehicleLabel(expense.vehicle, expense.vehicleId);

  static String _vehicleLabel(CostVehicleEmbed? vehicle, String vehicleId) {
    if (vehicle == null) {
      return vehicleId;
    }
    return '${vehicle.registrationNumber} · ${vehicle.name}';
  }

  static String formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
