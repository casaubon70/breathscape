import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/phase_adjuster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _patterns = [
  BreathingPattern(
    name: 'Box Breathing',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
    ],
  ),
];

Future<List<BreathingPattern>> _loader() async => _patterns;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget page() => MaterialApp(
    theme: darkOceanTheme.toThemeData(),
    home: const BreathingSessionPage(patternsLoader: _loader),
  );

  testWidgets('edit mode adjusts a phase duration and reflects it in the '
      'session', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // Idle session shows the first phase duration.
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('4s'), findsOneWidget);

    // Enter edit mode via the sliders icon.
    await tester.tap(find.byIcon(FontAwesomeIcons.sliders.data));
    await tester.pumpAndSettle();

    expect(find.byType(PhaseAdjuster), findsOneWidget);
    expect(find.text('INHALE'), findsOneWidget);

    // Increase the inhale duration twice (4 → 6).
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('6s'), findsOneWidget);

    // Leave edit mode — the session now starts from the edited inhale duration.
    await tester.tap(find.byIcon(FontAwesomeIcons.sliders.data));
    await tester.pumpAndSettle();

    expect(find.byType(PhaseAdjuster), findsNothing);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('6s'), findsOneWidget);
  });
}
