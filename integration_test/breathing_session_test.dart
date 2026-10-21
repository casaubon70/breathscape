import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:breathscape/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps frames until [finder] matches or [timeout] elapses.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

AppLocalizations _l10n(WidgetTester tester) {
  final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  if (l10n == null) fail('AppLocalizations not available');
  return l10n;
}

/// Starts the app with a fresh in-memory preference store and accepts the
/// disclaimer, leaving the session page ready.
Future<void> _launchToSessionPage(WidgetTester tester) async {
  // In-memory store: never touches the real app's preferences on device.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  await tester.pumpWidget(const BreathscapeApp());
  await _pumpUntilFound(tester, find.byType(DisclaimerPage));

  await tester.tap(find.text(_l10n(tester).disclaimerAcceptButton));
  await _pumpUntilFound(tester, find.byType(BreathingAnimationWidget));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Breathing session', () {
    testWidgets('Disclaimer → Play → Phase läuft → Pause', (tester) async {
      await _launchToSessionPage(tester);
      final l10n = _l10n(tester);

      expect(find.byType(BreathingSessionPage), findsOneWidget);
      expect(find.text(l10n.sessionReady), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle));
      await _pumpUntilFound(tester, find.byIcon(Icons.pause_circle));
      // Let the first phase run so the label switches away from READY.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l10n.sessionReady), findsNothing);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await _pumpUntilFound(tester, find.byIcon(Icons.play_circle));
      expect(find.text(l10n.sessionReady), findsOneWidget);
    });

    testWidgets('kein Overflow bei niedrigem Fenster', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 450)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _launchToSessionPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BreathingAnimationWidget), findsOneWidget);
    });
  });
}
