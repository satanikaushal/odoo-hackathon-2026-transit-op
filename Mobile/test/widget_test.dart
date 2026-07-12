import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_op/app.dart';
import 'package:transit_op/core/config/app_environment.dart';
import 'package:transit_op/core/di/injection.dart';
import 'package:transit_op/features/auth/application/auth_session_provider.dart';

class _UnauthenticatedAuthNotifier extends AuthSessionNotifier {
  @override
  AuthSessionState build() {
    return const AuthSessionState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  testWidgets('App redirects unauthenticated user to login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppEnvironment.setUp(Env.DEV);

    final sharedPreferences = await SharedPreferences.getInstance();
    await configureDependencies(sharedPreferences);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_UnauthenticatedAuthNotifier.new),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
