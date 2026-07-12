import 'package:flutter/material.dart';

import '../../shared/models/user_role.dart';
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
  static String defaultRoute(UserRole role) {
    return switch (role) {
      UserRole.fleetManager => AppRoutes.fleet,
      UserRole.dispatcher => AppRoutes.dashboard,
      UserRole.safetyOfficer => AppRoutes.drivers,
      UserRole.financialAnalyst => AppRoutes.expenses,
    };
  }

  static List<ShellNavItem> bottomNavItems(UserRole role) {
    return switch (role) {
      UserRole.fleetManager => const [
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
            label: 'Settings',
            icon: Icons.settings_outlined,
            route: AppRoutes.settings,
          ),
        ],
      UserRole.dispatcher => const [
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
            label: 'Settings',
            icon: Icons.settings_outlined,
            route: AppRoutes.settings,
          ),
        ],
      UserRole.safetyOfficer => const [
          ShellNavItem(
            label: 'Drivers',
            icon: Icons.person_outline,
            route: AppRoutes.drivers,
          ),
          ShellNavItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            route: AppRoutes.settings,
          ),
        ],
      UserRole.financialAnalyst => const [
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
          ShellNavItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            route: AppRoutes.settings,
          ),
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

    final allowedRoutes = bottomNavItems(role).map((item) => item.route).toSet();
    return allowedRoutes.contains(location);
  }

  static bool _isPublicRoute(String location) {
    return location == AppRoutes.splash ||
        location == AppRoutes.login ||
        location.startsWith(AppRoutes.unauthorized);
  }
}
