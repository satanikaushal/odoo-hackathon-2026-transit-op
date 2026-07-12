import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_environment.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/network_providers.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_dialogs.dart';
import 'features/auth/application/auth_session_provider.dart';
import 'shared/utils/responsive.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(diBridgeProvider);

    final router = ref.watch(appRouterProvider);

    ref.listen(apiErrorStateProvider, (previous, next) {
      if (next == null) {
        return;
      }

      showSnackBarMessage(context, next.message);
      ref.read(apiErrorStateProvider.notifier).state = null;
    });

    ref.listen(sessionExpiredProvider, (previous, next) {
      if (!next) {
        return;
      }

      ref.read(authSessionProvider.notifier).markUnauthenticated();
      router.go(AppRoutes.login);
      ref.read(sessionExpiredProvider.notifier).state = false;
    });

    final config = AppEnvironment.current;
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        Responsive.init(context);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
