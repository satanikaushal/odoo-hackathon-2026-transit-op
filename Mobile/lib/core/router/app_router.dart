import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';
import 'app_routes.dart';
import 'role_access.dart';
import 'shell_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._authState);

  AuthSessionState _authState;

  AuthSessionState get authState => _authState;

  void update(AuthSessionState authState) {
    if (_authState == authState) {
      return;
    }
    _authState = authState;
    notifyListeners();
  }
}

final routerListenableProvider = Provider<_AuthRefreshListenable>((ref) {
  final listenable = _AuthRefreshListenable(ref.read(authSessionProvider));
  ref.listen(authSessionProvider, (_, next) {
    listenable.update(next);
  });
  return listenable;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) => _redirect(listenable.authState, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final role = listenable.authState.role;
          if (role == null) {
            return child;
          }
          return ShellScaffold(role: role, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Dashboard'),
          ),
          GoRoute(
            path: AppRoutes.fleet,
            builder: (context, state) => const PlaceholderScreen(title: 'Fleet'),
          ),
          GoRoute(
            path: AppRoutes.drivers,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Drivers'),
          ),
          GoRoute(
            path: AppRoutes.trips,
            builder: (context, state) => const PlaceholderScreen(title: 'Trips'),
          ),
          GoRoute(
            path: AppRoutes.maintenance,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Maintenance'),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Fuel & Expenses'),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Analytics'),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Settings'),
          ),
        ],
      ),
    ],
  );
});

String? _redirect(AuthSessionState authState, String location) {
  final isSplash = location == AppRoutes.splash;
  final isLogin = location == AppRoutes.login;

  if (authState.status == AuthStatus.unknown) {
    return isSplash ? null : AppRoutes.splash;
  }

  if (!authState.isAuthenticated) {
    if (isLogin) {
      return null;
    }
    return AppRoutes.login;
  }

  final role = authState.role;
  if (role == null) {
    return AppRoutes.login;
  }

  if (isSplash || isLogin) {
    return RoleAccess.defaultRoute(role);
  }

  if (AppRoutes.isShellRoute(location) && !RoleAccess.canAccess(role, location)) {
    return AppRoutes.unauthorized;
  }

  return null;
}
