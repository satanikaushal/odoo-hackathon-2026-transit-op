import 'package:flutter_test/flutter_test.dart';
import 'package:transit_op/core/config/app_environment.dart';
import 'package:transit_op/main.dart';

void main() {
  testWidgets('App loads with dev environment config', (tester) async {
    AppEnvironment.setUp(Env.DEV);

    await tester.pumpWidget(const MyApp());

    expect(find.textContaining('TransitOps Dev'), findsOneWidget);
    expect(find.textContaining('dev-api.transitops.in'), findsOneWidget);
  });
}
