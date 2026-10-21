import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_driver.dart';

final Finder _gearIcon = find.byWidgetPredicate(
  (w) => w is FaIcon && w.icon?.codePoint == FontAwesomeIcons.gear.codePoint,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings', () {
    testWidgets('Zahnrad → Einstellungen → Schließen → Session', (
      tester,
    ) async {
      await launchToSessionPage(tester);

      await tester.tap(_gearIcon);
      await pumpUntilFound(tester, find.byType(SettingsPage));
      expect(find.text(l10nOf(tester).settingsTitle), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilFound(tester, _gearIcon);
      // Route transition must be finished before the page is gone.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(BreathingSessionPage), findsOneWidget);
    });
  });
}
