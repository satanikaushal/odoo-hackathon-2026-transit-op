abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const unauthorized = '/unauthorized';

  static const dashboard = '/dashboard';
  static const fleet = '/fleet';
  static const fleetAdd = '/fleet/add';
  static const drivers = '/drivers';
  static const driversAdd = '/drivers/add';
  static const trips = '/trips';
  static const tripsAdd = '/trips/add';
  static const maintenance = '/maintenance';
  static const maintenanceAdd = '/maintenance/add';
  static const expenses = '/expenses';
  static const fuelLogAdd = '/expenses/fuel/add';
  static const expenseRecordAdd = '/expenses/record/add';
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
    if (shellRoutes.contains(location)) {
      return true;
    }
    return shellSectionRoute(location) != null;
  }

  static String? shellSectionRoute(String location) {
    for (final route in shellRoutes) {
      if (location == route || location.startsWith('$route/')) {
        return route;
      }
    }
    return null;
  }

  static bool isNestedShellRoute(String location) {
    final section = shellSectionRoute(location);
    return section != null && location != section;
  }

  static String fleetDetail(String id) => '/fleet/$id';

  static String fleetEdit(String id) => '/fleet/$id/edit';

  static String driverDetail(String id) => '/drivers/$id';

  static String driverEdit(String id) => '/drivers/$id/edit';

  static String tripDetail(String id) => '/trips/$id';

  static String tripComplete(String id) => '/trips/$id/complete';

  static String maintenanceDetail(String id) => '/maintenance/$id';

  static String fuelLogDetail(String id) => '/expenses/fuel/$id';

  static String expenseRecordDetail(String id) => '/expenses/record/$id';

  static String? pageTitle(String location) {
    if (location == fleetAdd) {
      return 'Add Vehicle';
    }
    if (location == driversAdd) {
      return 'Add Driver';
    }
    if (location == tripsAdd) {
      return 'Create Trip';
    }
    if (location == maintenanceAdd) {
      return 'Open Maintenance';
    }
    if (location == fuelLogAdd) {
      return 'Log Fuel';
    }
    if (location == expenseRecordAdd) {
      return 'Add Expense';
    }
    if (_tripCompletePattern.hasMatch(location)) {
      return 'Complete Trip';
    }
    if (_fleetEditPattern.hasMatch(location)) {
      return 'Edit Vehicle';
    }
    if (_driverEditPattern.hasMatch(location)) {
      return 'Edit Driver';
    }
    if (_fleetDetailPattern.hasMatch(location)) {
      return 'Vehicle Details';
    }
    if (_driverDetailPattern.hasMatch(location)) {
      return 'Driver Details';
    }
    if (_tripDetailPattern.hasMatch(location)) {
      return 'Trip Details';
    }
    if (_maintenanceDetailPattern.hasMatch(location)) {
      return 'Maintenance Details';
    }
    if (_fuelLogDetailPattern.hasMatch(location)) {
      return 'Fuel Log Details';
    }
    if (_expenseRecordDetailPattern.hasMatch(location)) {
      return 'Expense Details';
    }

    return switch (shellSectionRoute(location)) {
      dashboard => 'Dashboard',
      fleet => 'Fleet',
      drivers => 'Drivers',
      trips => 'Trips',
      maintenance => 'Maintenance',
      expenses => 'Fuel & Expenses',
      analytics => 'Analytics',
      settings => 'Settings',
      _ => null,
    };
  }

  static final _fleetDetailPattern = RegExp(r'^/fleet/[^/]+$');
  static final _fleetEditPattern = RegExp(r'^/fleet/[^/]+/edit$');
  static final _driverDetailPattern = RegExp(r'^/drivers/[^/]+$');
  static final _driverEditPattern = RegExp(r'^/drivers/[^/]+/edit$');
  static final _tripDetailPattern = RegExp(r'^/trips/[^/]+$');
  static final _tripCompletePattern = RegExp(r'^/trips/[^/]+/complete$');
  static final _maintenanceDetailPattern = RegExp(r'^/maintenance/[^/]+$');
  static final _fuelLogDetailPattern = RegExp(r'^/expenses/fuel/[^/]+$');
  static final _expenseRecordDetailPattern = RegExp(r'^/expenses/record/[^/]+$');
}
