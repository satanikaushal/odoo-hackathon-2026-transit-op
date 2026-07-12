abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const unauthorized = '/unauthorized';

  static const dashboard = '/dashboard';
  static const fleet = '/fleet';
  static const drivers = '/drivers';
  static const trips = '/trips';
  static const maintenance = '/maintenance';
  static const expenses = '/expenses';
  static const analytics = '/analytics';
  static const settings = '/settings';

  static const shellRoutes = {
    dashboard,
    fleet,
    drivers,
    trips,
    maintenance,
    expenses,
    analytics,
    settings,
  };

  static bool isShellRoute(String location) {
    return shellRoutes.contains(location);
  }
}
