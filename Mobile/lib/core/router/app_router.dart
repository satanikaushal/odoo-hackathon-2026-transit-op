import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/fleet/presentation/screens/fleet_list_screen.dart';
import '../../features/fleet/presentation/screens/vehicle_detail_screen.dart';
import '../../features/fleet/presentation/screens/vehicle_form_screen.dart';
import '../../features/drivers/presentation/screens/driver_detail_screen.dart';
import '../../features/drivers/presentation/screens/driver_form_screen.dart';
import '../../features/drivers/presentation/screens/drivers_list_screen.dart';
import '../../features/trips/presentation/screens/trip_complete_screen.dart';
import '../../features/trips/presentation/screens/trip_detail_screen.dart';
import '../../features/trips/presentation/screens/trip_form_screen.dart';
import '../../features/trips/presentation/screens/trips_list_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_form_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/expenses/presentation/screens/expenses_hub_screen.dart';
import '../../features/expenses/presentation/screens/fuel_log_detail_screen.dart';
import '../../features/expenses/presentation/screens/fuel_log_form_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/opaque_route_background.dart';
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
        pageBuilder: (context, state, child) {
          final role = listenable.authState.role;
          final shell = role == null
              ? child
              : ShellScaffold(role: role, child: child);
          return _noTransitionPage(state, shell);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.fleet,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const FleetListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const VehicleFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  VehicleDetailScreen(
                    vehicleId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _materialPage(
                      state,
                      VehicleFormScreen(
                        vehicleId: state.pathParameters['id'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.drivers,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const DriversListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const DriverFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  DriverDetailScreen(
                    driverId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _materialPage(
                      state,
                      DriverFormScreen(
                        driverId: state.pathParameters['id'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.trips,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const TripsListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const TripFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  TripDetailScreen(
                    tripId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'complete',
                    pageBuilder: (context, state) => _materialPage(
                      state,
                      TripCompleteScreen(
                        tripId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.maintenance,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const MaintenanceListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const MaintenanceFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  MaintenanceDetailScreen(
                    logId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.expenses,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const ExpensesHubScreen(),
            ),
            routes: [
              GoRoute(
                path: 'fuel/add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const FuelLogFormScreen(),
                ),
              ),
              GoRoute(
                path: 'fuel/:id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  FuelLogDetailScreen(
                    logId: state.pathParameters['id']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'record/add',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  const ExpenseFormScreen(),
                ),
              ),
              GoRoute(
                path: 'record/:id',
                pageBuilder: (context, state) => _materialPage(
                  state,
                  ExpenseDetailScreen(
                    expenseId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.analytics,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

NoTransitionPage<void> _noTransitionPage(
  GoRouterState state,
  Widget child,
) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

MaterialPage<void> _materialPage(
  GoRouterState state,
  Widget child,
) {
  return MaterialPage<void>(
    key: state.pageKey,
    child: OpaqueRouteBackground(
      child: SubRouteScaffold(body: child),
    ),
  );
}

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
