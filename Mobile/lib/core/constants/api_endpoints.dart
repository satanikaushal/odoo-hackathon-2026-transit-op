abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const dashboard = '/dashboard';
  static const vehicles = '/vehicles';
  static const drivers = '/drivers';
  static const trips = '/trips';
  static const maintenance = '/maintenance';
  static const fuelLogs = '/fuel-logs';
  static const expenses = '/expenses';
  static const analytics = '/analytics';
  static const settings = '/settings';
}

abstract final class ApiExtras {
  static const retry = 'retry';
  static const retryCount = 'retry_count';
}
