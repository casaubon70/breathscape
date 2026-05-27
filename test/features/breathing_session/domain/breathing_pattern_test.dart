import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathingPattern', () {
    test('stores name and phases correctly', () {
      const pattern = BreathingPattern(
        name: 'Box Breathing',
        phases: [
          BreathingPhase(
            type: PhaseType.inhale,
            duration: Duration(seconds: 4),
          ),
          BreathingPhase(
            type: PhaseType.holdIn,
            duration: Duration(seconds: 4),
          ),
          BreathingPhase(
            type: PhaseType.exhale,
            duration: Duration(seconds: 4),
          ),
          BreathingPhase(
            type: PhaseType.holdOut,
            duration: Duration(seconds: 4),
          ),
        ],
      );

      expect(pattern.name, 'Box Breathing');
      expect(pattern.phases.length, 4);
    });

    test('phases are accessible in order', () {
      const pattern = BreathingPattern(
        name: '4-7-8',
        phases: [
          BreathingPhase(
            type: PhaseType.inhale,
            duration: Duration(seconds: 4),
          ),
          BreathingPhase(
            type: PhaseType.holdIn,
            duration: Duration(seconds: 7),
          ),
          BreathingPhase(
            type: PhaseType.exhale,
            duration: Duration(seconds: 8),
          ),
        ],
      );

      expect(pattern.phases[0].type, PhaseType.inhale);
      expect(pattern.phases[1].type, PhaseType.holdIn);
      expect(pattern.phases[2].type, PhaseType.exhale);
      expect(pattern.phases[1].duration, const Duration(seconds: 7));
    });

    test('pattern with empty phases is valid', () {
      const pattern = BreathingPattern(name: 'Empty', phases: []);
      expect(pattern.phases, isEmpty);
    });
  });
}
