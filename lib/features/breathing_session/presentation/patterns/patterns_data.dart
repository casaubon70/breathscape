import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';

abstract class PatternsData {
  static const boxBreathing = BreathingPattern(
    name: 'Box Breathing',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdIn, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdOut, duration: Duration(seconds: 4)),
    ],
  );
}
