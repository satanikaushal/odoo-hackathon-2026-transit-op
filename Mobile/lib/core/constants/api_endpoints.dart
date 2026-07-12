abstract final class ApiEndpoints {
  static const health = '/health';

  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const dashboardKpis = '/dashboard/kpis';
  static const dashboardFilters = '/dashboard/filters';
  static const vehicles = '/vehicles';
  static const drivers = '/drivers';
  static const trips = '/trips';
  static const maintenance = '/maintenance';
  static const fuelLogs = '/fuel-logs';
  static const expenses = '/expenses';
  static const analytics = '/analytics';
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
