import 'package:flutter/material.dart';

import '../../shared/models/user_role.dart';
import '../../features/expenses/domain/expenses_permissions.dart';
import 'app_routes.dart';

class ShellNavItem {
  const ShellNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

abstract final class RoleAccess {
  static const _settingsNavItem = ShellNavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: AppRoutes.settings,
  );

  static String defaultRoute(UserRole role) {
    return switch (role) {
      UserRole.ADMIN => AppRoutes.dashboard,
      UserRole.FLEET_MANAGER => AppRoutes.fleet,
      UserRole.DRIVER => AppRoutes.dashboard,
      UserRole.SAFETY_OFFICER => AppRoutes.drivers,
      UserRole.FINANCIAL_ANALYST => AppRoutes.expenses,
    };
  }

  static List<ShellNavItem> sidebarNavItems(UserRole role) {
    return switch (role) {
      UserRole.ADMIN => _adminNavItems,
      UserRole.FLEET_MANAGER => const [
          ShellNavItem(
            label: 'Fleet',
            icon: Icons.local_shipping_outlined,
            route: AppRoutes.fleet,
          ),
          ShellNavItem(
            label: 'Maintenance',
            icon: Icons.build_outlined,
            route: AppRoutes.maintenance,
          ),
          ShellNavItem(
            label: 'Fuel & Expenses',
            icon: Icons.payments_outlined,
            route: AppRoutes.expenses,
          ),
          _settingsNavItem,
        ],
      UserRole.DRIVER => const [
          ShellNavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            route: AppRoutes.dashboard,
          ),
          ShellNavItem(
            label: 'Trips',
            icon: Icons.route_outlined,
            route: AppRoutes.trips,
          ),
          ShellNavItem(
            label: 'Fuel Logs',
            icon: Icons.local_gas_station_outlined,
            route: AppRoutes.expenses,
          ),
          _settingsNavItem,
        ],
      UserRole.SAFETY_OFFICER => const [
          ShellNavItem(
            label: 'Drivers',
            icon: Icons.person_outline,
            route: AppRoutes.drivers,
          ),
          _settingsNavItem,
        ],
      UserRole.FINANCIAL_ANALYST => const [
          ShellNavItem(
            label: 'Expenses',
            icon: Icons.payments_outlined,
            route: AppRoutes.expenses,
          ),
          ShellNavItem(
            label: 'Analytics',
            icon: Icons.bar_chart_outlined,
            route: AppRoutes.analytics,
          ),
          _settingsNavItem,
        ],
    };
  }

  static bool canAccess(UserRole? role, String location) {
    if (role == null) {
      return false;
    }

    if (_isPublicRoute(location)) {
      return true;
    }

    if (!_canAccessExpensesSubRoute(role, location)) {
      return false;
    }

    final sectionRoute = AppRoutes.shellSectionRoute(location) ?? location;

    final allowedRoutes =
        sidebarNavItems(role).map((item) => item.route).toSet();
    if (role == UserRole.ADMIN) {
      return AppRoutes.isShellRoute(location);
    }
    return allowedRoutes.contains(sectionRoute);
  }

  static bool _isPublicRoute(String location) {
    return location == AppRoutes.splash ||
        location == AppRoutes.login ||
        location.startsWith(AppRoutes.unauthorized);
  }

  static bool _canAccessExpensesSubRoute(UserRole role, String location) {
    if (location == AppRoutes.fuelLogAdd) {
      return role.canCreateFuelLogs;
    }
    if (location == AppRoutes.expenseRecordAdd) {
      return role.canCreateExpenses;
    }
    if (location.startsWith('${AppRoutes.expenses}/fuel/')) {
      return role.canReadFuelLogs;
    }
    if (location.startsWith('${AppRoutes.expenses}/record/')) {
      return role.canReadExpenses;
    }
    if (location == AppRoutes.expenses) {
      return role.canReadFuelLogs || role.canReadExpenses;
    }
    return true;
  }

  static const List<ShellNavItem> _adminNavItems = [
    ShellNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: AppRoutes.dashboard,
    ),
    ShellNavItem(
      label: 'Fleet',
      icon: Icons.local_shipping_outlined,
      route: AppRoutes.fleet,
    ),
    ShellNavItem(
      label: 'Drivers',
      icon: Icons.person_outline,
      route: AppRoutes.drivers,
    ),
    ShellNavItem(
      label: 'Trips',
      icon: Icons.route_outlined,
      route: AppRoutes.trips,
    ),
    ShellNavItem(
      label: 'Maintenance',
      icon: Icons.build_outlined,
      route: AppRoutes.maintenance,
    ),
    ShellNavItem(
      label: 'Fuel & Expenses',
      icon: Icons.payments_outlined,
      route: AppRoutes.expenses,
    ),
    ShellNavItem(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      route: AppRoutes.analytics,
    ),
    ShellNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
    ),
  ];
}
