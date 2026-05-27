import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathingSessionPage', () {
    testWidgets('renders AnimationWidget und PlaybackControls', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BreathingSessionPage()));

      expect(find.byType(BreathingAnimationWidget), findsOneWidget);
      expect(find.byType(PlaybackControls), findsOneWidget);
    });

    testWidgets('zeigt Play-Icon im Idle-State', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BreathingSessionPage()));

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle), findsNothing);
    });

    testWidgets('Tap Play → Pause-Icon erscheint', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BreathingSessionPage()));

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();

      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsNothing);
    });

    testWidgets('Tap Play dann Pause → Play-Icon kehrt zurück', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BreathingSessionPage()));

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause_circle));
      await tester.pump();

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
    });

    testWidgets('zeigt Phasen-Label und Zyklus-Anzeige', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BreathingSessionPage()));

      expect(find.text('INHALE'), findsOneWidget);
      expect(find.text('Cycle 1'), findsOneWidget);
    });
  });
}
