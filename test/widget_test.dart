import 'package:breathscape/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app renders without error', (tester) async {
    await tester.pumpWidget(const BreathscapeApp());
    expect(find.byType(BreathscapeApp), findsOneWidget);
  });
}
