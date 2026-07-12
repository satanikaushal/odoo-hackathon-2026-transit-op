// ignore_for_file: constant_identifier_names

enum DriverStatus {
  AVAILABLE,
  ON_TRIP,
  OFF_DUTY,
  SUSPENDED;

  String get label {
    return switch (this) {
      DriverStatus.AVAILABLE => 'Available',
      DriverStatus.ON_TRIP => 'On Trip',
      DriverStatus.OFF_DUTY => 'Off Duty',
      DriverStatus.SUSPENDED => 'Suspended',
    };
  }

  static DriverStatus? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in DriverStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}
