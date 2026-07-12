import '../domain/models/dashboard_filter_options.dart';
import '../domain/models/dashboard_kpis.dart';
import '../domain/models/dashboard_trip_summary.dart';
import '../domain/models/vehicle_status_breakdown.dart';

abstract final class DashboardMockData {
  static const kpis = DashboardKpis(
    activeVehicles: 53,
    availableVehicles: 42,
    vehiclesInMaintenance: 5,
    activeTrips: 18,
    pendingTrips: 9,
    driversOnDuty: 26,
    fleetUtilization: 81,
  );

  static const filterOptions = DashboardFilterOptions(
    types: ['Van', 'Truck', 'Mini'],
    regions: ['North', 'South', 'East', 'West'],
    statuses: ['AVAILABLE', 'ON_TRIP', 'IN_SHOP', 'RETIRED'],
  );

  static const recentTrips = <DashboardTripSummary>[
    DashboardTripSummary(
      tripId: 'TR001',
      vehicle: 'VAN-05',
      driver: 'Alex',
      status: TripSummaryStatus.onTrip,
      eta: '45 min',
    ),
    DashboardTripSummary(
      tripId: 'TR002',
      vehicle: 'TRK-12',
      driver: 'John',
      status: TripSummaryStatus.completed,
      eta: '—',
    ),
    DashboardTripSummary(
      tripId: 'TR003',
      vehicle: 'MINI-08',
      driver: 'Priya',
      status: TripSummaryStatus.dispatched,
      eta: '1h 10m',
    ),
    DashboardTripSummary(
      tripId: 'TR004',
      vehicle: '—',
      driver: '—',
      status: TripSummaryStatus.draft,
      eta: 'Awaiting vehicle',
    ),
  ];

  static const vehicleStatus = VehicleStatusBreakdown(
    items: [
      VehicleStatusBreakdownItem(
        bucket: VehicleStatusBucket.available,
        count: 42,
      ),
      VehicleStatusBreakdownItem(
        bucket: VehicleStatusBucket.onTrip,
        count: 53,
      ),
      VehicleStatusBreakdownItem(
        bucket: VehicleStatusBucket.inShop,
        count: 5,
      ),
      VehicleStatusBreakdownItem(
        bucket: VehicleStatusBucket.retired,
        count: 2,
      ),
    ],
  );
}
