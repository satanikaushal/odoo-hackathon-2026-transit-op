// ignore_for_file: constant_identifier_names

enum MaintenanceStatus {
  OPEN,
  CLOSED;

  String get label {
    return switch (this) {
      MaintenanceStatus.OPEN => 'Open',
      MaintenanceStatus.CLOSED => 'Closed',
    };
  }

  static MaintenanceStatus? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in MaintenanceStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}
