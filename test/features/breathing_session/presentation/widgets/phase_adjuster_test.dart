import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/phase_adjuster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phases = [
  BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
  BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
];

void main() {
  Widget build({
    required void Function(int, int) onChanged,
    List<BreathingPhase> phases = _phases,
    VoidCallback? onReset,
  }) => MaterialApp(
    theme: darkOceanTheme.toThemeData(),
    home: Scaffold(
      body: PhaseAdjuster(
        phases: phases,
        onChanged: onChanged,
        onReset: onReset,
      ),
    ),
  );

  group('PhaseAdjuster', () {
    testWidgets('renders a label and value for each phase', (tester) async {
      await tester.pumpWidget(build(onChanged: (_, __) {}));

      expect(find.text('INHALE'), findsOneWidget);
      expect(find.text('EXHALE'), findsOneWidget);
      expect(find.text('4s'), findsNWidgets(2));
    });

    testWidgets('increase button reports seconds + 1 for that phase', (
      tester,
    ) async {
      int? index;
      int? seconds;
      await tester.pumpWidget(
        build(
          onChanged: (i, s) {
            index = i;
            seconds = s;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);

      expect(index, 0);
      expect(seconds, 5);
    });

    testWidgets('decrease button reports seconds - 1 for that phase', (
      tester,
    ) async {
      int? index;
      int? seconds;
      await tester.pumpWidget(
        build(
          onChanged: (i, s) {
            index = i;
            seconds = s;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline).last);

      expect(index, 1);
      expect(seconds, 3);
    });

    testWidgets('decrease is disabled at the minimum', (tester) async {
      var called = false;
      await tester.pumpWidget(
        build(
          phases: const [
            BreathingPhase(
              type: PhaseType.inhale,
              duration: Duration(seconds: 1),
            ),
          ],
          onChanged: (_, __) => called = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));

      expect(called, isFalse);
    });

    testWidgets('reset button is shown and invokes onReset', (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        build(onChanged: (_, __) {}, onReset: () => resetCalled = true),
      );

      await tester.tap(find.text('AUF STANDARD ZURÜCKSETZEN'));

      expect(resetCalled, isTrue);
    });
  });
}
