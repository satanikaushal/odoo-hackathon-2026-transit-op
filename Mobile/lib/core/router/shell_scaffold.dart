import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../../shared/models/user_role.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/widgets/app_text.dart';
import '../config/app_environment.dart';
import 'app_routes.dart';
import 'role_access.dart';

/// Breakpoint above which the web-style sidebar stays pinned open.
const kPersistentSidebarBreakpoint = 840.0;

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.role,
    required this.selectedRoute,
    required this.onDestinationSelected,
    this.closeOnSelect = false,
  });

  final UserRole role;
  final String selectedRoute;
  final ValueChanged<String> onDestinationSelected;
  final bool closeOnSelect;

  @override
  Widget build(BuildContext context) {
    final navItems = RoleAccess.sidebarNavItems(role);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SidebarHeader(),
            Expanded(
              child: ListView.builder(
                padding: Responsive.getPaddingSymmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  return _SidebarNavTile(
                    item: item,
                    isSelected: item.route == selectedRoute,
                    onTap: () {
                      onDestinationSelected(item.route);
                      if (closeOnSelect) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appName = AppEnvironment.current.appName;

    return Padding(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            color: colorScheme.primary,
            size: Responsive.getSize(28),
          ),
          Responsive.horizontalGap(12),
          Expanded(
            child: AppText(
              appName,
              size: 16,
              fontWeight: FontWeight.w700,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Responsive.getR(10)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.getR(10)),
          child: Container(
            padding: Responsive.getPaddingSymmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.getR(10)),
              border: isSelected
                  ? Border(
                      left: BorderSide(color: colorScheme.primary, width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, color: foregroundColor, size: 22),
                Responsive.horizontalGap(12),
                Expanded(
                  child: AppText(
                    item.label,
                    size: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final location = GoRouterState.of(context).uri.path;
    final sectionRoute = AppRoutes.shellSectionRoute(location) ?? location;
    final navItems = RoleAccess.sidebarNavItems(role);
    final currentItem = navItems.firstWhere(
      (item) => item.route == sectionRoute,
      orElse: () => navItems.first,
    );
    final pageTitle = AppRoutes.pageTitle(location) ?? currentItem.label;
    final showBack = AppRoutes.isNestedShellRoute(location);
    final usePersistentSidebar =
        MediaQuery.sizeOf(context).width >= kPersistentSidebarBreakpoint;

    final sidebar = AppSidebar(
      role: role,
      selectedRoute: sectionRoute,
      closeOnSelect: !usePersistentSidebar,
      onDestinationSelected: context.go,
    );

    if (usePersistentSidebar) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: sidebar,
              ),
            ),
            Expanded(
              child: _ShellMainContent(
                title: pageTitle,
                showBack: showBack,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !showBack,
        leading: showBack
            ? BackButton(onPressed: () => context.pop())
            : null,
        title: AppText(
          pageTitle,
          size: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawer: showBack ? null : Drawer(width: 280, child: sidebar),
      body: child,
    );
  }
}

class _ShellMainContent extends StatelessWidget {
  const _ShellMainContent({
    required this.title,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: Responsive.getPaddingSymmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Row(
                children: [
                  if (showBack) ...[
                    BackButton(onPressed: () => context.pop()),
                    Responsive.horizontalGap(8),
                  ],
                  Expanded(
                    child: AppText(
                      title,
                      size: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Expanded(child: child),
      ],
    );
  }
}

class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;

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
            Responsive.verticalGap(24),
            FilledButton(
              onPressed: role == null
                  ? null
                  : () => context.go(RoleAccess.defaultRoute(role)),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
