import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/disclaimer/domain/disclaimer_repository.dart';
import 'package:breathscape/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:breathscape/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_driver.dart';

const _prefsKey = 'disclaimer_accepted_version';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Disclaimer', () {
    testWidgets('Erststart → Zustimmen → Session; Neustart ohne Disclaimer', (
      tester,
    ) async {
      await launchApp(tester);
      await pumpUntilFound(tester, find.byType(DisclaimerPage));
      expect(find.byType(BreathingSessionPage), findsNothing);

      await tester.tap(find.text(l10nOf(tester).disclaimerAcceptButton));
      await pumpUntilFound(tester, find.byType(BreathingAnimationWidget));
      expect(find.byType(DisclaimerPage), findsNothing);

      // Relaunch with the same preference store: consent must persist.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const BreathscapeApp());
      await pumpUntilFound(tester, find.byType(BreathingAnimationWidget));
      expect(find.byType(DisclaimerPage), findsNothing);
    });

    testWidgets('veraltete Zustimmung → Disclaimer erscheint erneut', (
      tester,
    ) async {
      await launchApp(
        tester,
        preferences: const {_prefsKey: DisclaimerRepository.currentVersion - 1},
      );
      await pumpUntilFound(tester, find.byType(DisclaimerPage));
      expect(find.byType(BreathingSessionPage), findsNothing);
    });

    testWidgets('aktuelle Zustimmung → direkt zur Session', (tester) async {
      await launchApp(
        tester,
        preferences: const {_prefsKey: DisclaimerRepository.currentVersion},
      );
      await pumpUntilFound(tester, find.byType(BreathingAnimationWidget));
      expect(find.byType(DisclaimerPage), findsNothing);
    });
  });
}
