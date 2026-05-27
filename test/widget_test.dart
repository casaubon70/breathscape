import 'package:breathscape/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders without error', (tester) async {
    await tester.pumpWidget(const BreathscapeApp());
    expect(find.byType(BreathscapeApp), findsOneWidget);
  });
}
