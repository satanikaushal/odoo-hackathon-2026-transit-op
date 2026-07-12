import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_op/app.dart';
import 'package:transit_op/core/config/app_environment.dart';
import 'package:transit_op/core/providers/core_providers.dart';

void main() {
  testWidgets('App loads with dev environment config', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppEnvironment.setUp(Env.DEV);

    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );

    expect(find.textContaining('TransitOps Dev'), findsOneWidget);
    expect(find.textContaining('dev-api.transitops.in'), findsOneWidget);
  });
}
