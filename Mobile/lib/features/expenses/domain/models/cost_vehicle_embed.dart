class CostVehicleEmbed {
  const CostVehicleEmbed({
    required this.id,
    required this.registrationNumber,
    required this.name,
    required this.status,
  });

  final String id;
  final String registrationNumber;
  final String name;
  final String status;

  factory CostVehicleEmbed.fromJson(Map<String, dynamic> json) {
    return CostVehicleEmbed(
      id: json['id'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
