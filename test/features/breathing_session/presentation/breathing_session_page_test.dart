import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _testPatterns = [
  BreathingPattern(
    name: 'Test Pattern',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
    ],
  ),
];

Future<List<BreathingPattern>> _loadTestPatterns() async => _testPatterns;

Widget _buildPage() => const MaterialApp(
  home: BreathingSessionPage(patternsLoader: _loadTestPatterns),
);

void main() {
  group('BreathingSessionPage', () {
    testWidgets('renders AnimationWidget und PlaybackControls', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.byType(BreathingAnimationWidget), findsOneWidget);
      expect(find.byType(PlaybackControls), findsOneWidget);
    });

    testWidgets('zeigt Play-Icon im Idle-State', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle), findsNothing);
    });

    testWidgets('Tap Play → Pause-Icon erscheint', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();

      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsNothing);
    });

    testWidgets('Tap Play dann Pause → Play-Icon kehrt zurück', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause_circle));
      await tester.pump();

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
    });

    testWidgets('zeigt Phasen-Label und verbleibende Sekunden', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('INHALE'), findsOneWidget);
      expect(find.text('4s'), findsOneWidget);
    });

    testWidgets('zeigt Pattern-Dropdown mit Pattern-Name', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Test Pattern'), findsOneWidget);
    });
  });
}
