abstract final class ApiEndpoints {
  static const health = '/health';

  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const dashboardKpis = '/dashboard/kpis';
  static const dashboardFilters = '/dashboard/filters';

  static const vehicles = '/vehicles';
  static String vehicle(String id) => '/vehicles/$id';
  static String vehicleStatus(String id) => '/vehicles/$id/status';
  static String vehicleCosts(String id) => '/vehicles/$id/costs';
  static const drivers = '/drivers';
  static String driver(String id) => '/drivers/$id';
  static const trips = '/trips';
  static String trip(String id) => '/trips/$id';
  static String tripDispatch(String id) => '/trips/$id/dispatch';
  static String tripComplete(String id) => '/trips/$id/complete';
  static String tripCancel(String id) => '/trips/$id/cancel';
  static const maintenance = '/maintenance';
  static String maintenanceLog(String id) => '/maintenance/$id';
  static String maintenanceClose(String id) => '/maintenance/$id/close';
  static const fuelLogs = '/fuel-logs';
  static String fuelLog(String id) => '/fuel-logs/$id';
  static const expenses = '/expenses';
  static String expense(String id) => '/expenses/$id';
  static const reportsFuelEfficiency = '/reports/fuel-efficiency';
  static const reportsFleetUtilization = '/reports/fleet-utilization';
  static const reportsOperationalCost = '/reports/operational-cost';
  static const reportsVehicleRoi = '/reports/vehicle-roi';
  static const reportsExportCsv = '/reports/export.csv';
  static const settings = '/settings';

  static bool skipsTokenRefresh(String path) {
    final normalized = Uri.tryParse(path)?.path ?? path;
    return normalized.endsWith(authLogin) || normalized.endsWith(authRefresh);
  }
}

abstract final class ApiExtras {
  static const retry = 'retry';
  static const retryCount = 'retry_count';
  static const retriedAfterRefresh = 'retried_after_refresh';
}
