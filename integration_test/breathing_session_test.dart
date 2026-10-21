import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Breathing session', () {
    testWidgets('Disclaimer → Play → Phase läuft → Pause', (tester) async {
      await launchToSessionPage(tester);
      final l10n = l10nOf(tester);

      expect(find.byType(BreathingSessionPage), findsOneWidget);
      expect(find.text(l10n.sessionReady), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle));
      await pumpUntilFound(tester, find.byIcon(Icons.pause_circle));
      // Let the first phase run so the label switches away from READY.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l10n.sessionReady), findsNothing);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await pumpUntilFound(tester, find.byIcon(Icons.play_circle));
      expect(find.text(l10n.sessionReady), findsOneWidget);
    });

    testWidgets('kein Overflow bei niedrigem Fenster', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 450)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await launchToSessionPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BreathingAnimationWidget), findsOneWidget);
    });
  });
}
