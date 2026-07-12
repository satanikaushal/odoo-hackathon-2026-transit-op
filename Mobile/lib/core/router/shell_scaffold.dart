import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/user_role.dart';
import '../../shared/utils/responsive.dart';
import 'role_access.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.child,
    required this.role,
  });

  final Widget child;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final navItems = RoleAccess.bottomNavItems(role);
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(navItems, location),
        onDestinationSelected: (index) {
          context.go(navItems[index].route);
        },
        destinations: navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(List<ShellNavItem> items, String location) {
    final index = items.indexWhere((item) => item.route == location);
    return index >= 0 ? index : 0;
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPadding(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            Responsive.verticalGap(16),
            Text(
              'You do not have access to this module.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Responsive.getF(16)),
            ),
          ],
        ),
      ),
    );
  }
}
