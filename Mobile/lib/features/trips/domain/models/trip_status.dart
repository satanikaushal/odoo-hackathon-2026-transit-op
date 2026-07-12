// ignore_for_file: constant_identifier_names

enum TripStatus {
  DRAFT,
  DISPATCHED,
  COMPLETED,
  CANCELLED;

  String get label {
    return switch (this) {
      TripStatus.DRAFT => 'Draft',
      TripStatus.DISPATCHED => 'Dispatched',
      TripStatus.COMPLETED => 'Completed',
      TripStatus.CANCELLED => 'Cancelled',
    };
  }

  static TripStatus? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in TripStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}
