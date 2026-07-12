enum TripSummaryStatus {
  onTrip,
  completed,
  dispatched,
  draft;

  String get label {
    return switch (this) {
      TripSummaryStatus.onTrip => 'On Trip',
      TripSummaryStatus.completed => 'Completed',
      TripSummaryStatus.dispatched => 'Dispatched',
      TripSummaryStatus.draft => 'Draft',
    };
  }
}

class DashboardTripSummary {
  const DashboardTripSummary({
    required this.tripId,
    required this.vehicle,
    required this.driver,
    required this.status,
    required this.eta,
  });

  final String tripId;
  final String vehicle;
  final String driver;
  final TripSummaryStatus status;
  final String eta;
}
