import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _testPrograms = [
  SessionProgram(
    name: 'Test Pattern',
    segments: [
      SessionSegment(
        label: 'Test Pattern',
        cycleCount: 10,
        cycleSpecs: [
          [
            PhaseSpec(
              type: PhaseType.inhale,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
            PhaseSpec(
              type: PhaseType.exhale,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
          ],
        ],
      ),
    ],
  ),
];

Future<List<SessionProgram>> _loadTestPrograms() async => _testPrograms;

Widget _buildPage() => MaterialApp(
  theme: darkOceanTheme.toThemeData(),
  home: const BreathingSessionPage(programsLoader: _loadTestPrograms),
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

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('4s'), findsOneWidget);
    });

    testWidgets('zeigt Pattern-Dropdown mit Pattern-Name', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Test Pattern'), findsOneWidget);
    });
  });

  group('PlaybackControls – Completed State', () {
    Widget buildControls(SessionStatus status) => MaterialApp(
      theme: darkOceanTheme.toThemeData(),
      home: Scaffold(
        body: PlaybackControls(
          status: status,
          onPlay: () {},
          onPause: () {},
          onReset: () {},
        ),
      ),
    );

    testWidgets('completed: Play ausgegraut, Replay-Button sichtbar', (
      tester,
    ) async {
      await tester.pumpWidget(buildControls(SessionStatus.completed));

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(
        find.byIcon(FontAwesomeIcons.arrowRotateLeft.data),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.pause_circle), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('idle: zeigt Play-Icon und Replay-Reset-Icon', (tester) async {
      await tester.pumpWidget(buildControls(SessionStatus.idle));

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(
        find.byIcon(FontAwesomeIcons.arrowRotateLeft.data),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('playing: zeigt Pause-Icon und Replay-Reset-Icon', (
      tester,
    ) async {
      await tester.pumpWidget(buildControls(SessionStatus.playing));

      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      expect(
        find.byIcon(FontAwesomeIcons.arrowRotateLeft.data),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('Tap Replay ruft onReset auf', (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: darkOceanTheme.toThemeData(),
          home: Scaffold(
            body: PlaybackControls(
              status: SessionStatus.completed,
              onPlay: () {},
              onPause: () {},
              onReset: () => resetCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(FontAwesomeIcons.arrowRotateLeft.data));
      expect(resetCalled, isTrue);
    });
  });
}
