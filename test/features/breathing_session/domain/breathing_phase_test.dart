import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathingPhase', () {
    test('stores type and duration correctly', () {
      const phase = BreathingPhase(
        type: PhaseType.inhale,
        duration: Duration(seconds: 4),
      );

      expect(phase.type, PhaseType.inhale);
      expect(phase.duration, const Duration(seconds: 4));
    });

    test('all PhaseType values are distinct', () {
      const values = PhaseType.values;
      expect(values.toSet().length, values.length);
    });

    test(
      'PhaseType contains all required values including extended phases',
      () {
        expect(
          PhaseType.values,
          containsAll([
            PhaseType.inhale,
            PhaseType.extendedInhale,
            PhaseType.holdIn,
            PhaseType.exhale,
            PhaseType.extendedExhale,
            PhaseType.holdOut,
          ]),
        );
      },
    );
  });
}
