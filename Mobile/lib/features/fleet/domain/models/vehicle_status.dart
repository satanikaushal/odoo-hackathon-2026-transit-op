// ignore_for_file: constant_identifier_names

enum VehicleStatus {
  AVAILABLE,
  ON_TRIP,
  IN_SHOP,
  RETIRED;

  String get label {
    return switch (this) {
      VehicleStatus.AVAILABLE => 'Available',
      VehicleStatus.ON_TRIP => 'On Trip',
      VehicleStatus.IN_SHOP => 'In Shop',
      VehicleStatus.RETIRED => 'Retired',
    };
  }

  static VehicleStatus? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in VehicleStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}
