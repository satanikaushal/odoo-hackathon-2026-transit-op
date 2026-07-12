import 'cost_vehicle_embed.dart';
import 'expense_category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.tripId,
    this.description,
    this.vehicle,
  });

  final String id;
  final String vehicleId;
  final String? tripId;
  final ExpenseCategory category;
  final String amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final CostVehicleEmbed? vehicle;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      tripId: json['tripId'] as String?,
      category: ExpenseCategory.fromString(json['category'] as String?) ??
          ExpenseCategory.misc,
      amount: json['amount']?.toString() ?? '0',
      description: json['description'] as String?,
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? CostVehicleEmbed.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
