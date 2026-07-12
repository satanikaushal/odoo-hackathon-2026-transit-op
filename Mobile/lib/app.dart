import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_environment.dart';
import 'core/providers/network_providers.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(apiErrorStateProvider, (previous, next) {
      if (next == null) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(next.message)),
      );
      ref.read(apiErrorStateProvider.notifier).state = null;
    });

    ref.listen(sessionExpiredProvider, (previous, next) {
      if (!next) {
        return;
      }

      rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
      ref.read(sessionExpiredProvider.notifier).state = false;
    });

    final config = AppEnvironment.current;

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: config.appName,
      debugShowCheckedModeBanner: config.env == Env.DEV,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => Scaffold(
              body: Center(
                child: Text('${config.appName}\n${config.baseUrl}'),
              ),
            ),
        AppRoutes.login: (_) => const Scaffold(
              body: Center(child: Text('Login')),
            ),
      },
    );
  }
}
