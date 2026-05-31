import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';

/// Converts a [BreathingPattern] to a [SessionProgram] with a single segment.
///
/// Handles [BreathingPattern.extendedExhaleInterval] and
/// [BreathingPattern.extendedInhaleInterval] by building cycleSpecs of length
/// lcm(exhaleInterval, inhaleInterval), where the triggering indices carry the
/// extended phase type and the extra +2 s duration.
SessionProgram migratePatternToProgram(BreathingPattern pattern) {
  final exhaleInterval = pattern.extendedExhaleInterval;
  final inhaleInterval = pattern.extendedInhaleInterval;

  if (exhaleInterval == null && inhaleInterval == null) {
    return SessionProgram(
      name: pattern.name,
      segments: [
        SessionSegment(
          label: pattern.name,
          cycleCount: pattern.defaultCycles,
          cycleSpecs: [_toPhaseSpecs(pattern.phases)],
        ),
      ],
    );
  }

  final k = _lcm(exhaleInterval ?? 1, inhaleInterval ?? 1);
  return SessionProgram(
    name: pattern.name,
    segments: [
      SessionSegment(
        label: pattern.name,
        cycleCount: pattern.defaultCycles,
        cycleSpecs: List.generate(
          k,
          (i) => _buildCycleSpec(
            pattern.phases,
            i,
            exhaleInterval,
            inhaleInterval,
          ),
        ),
      ),
    ],
  );
}

List<PhaseSpec> _toPhaseSpecs(List<BreathingPhase> phases) => phases
    .map(
      (p) => PhaseSpec(
        type: p.type,
        progression: FixedProgression(p.duration),
      ),
    )
    .toList();

/// Builds the phase spec list for cycleSpec at position [i] (0-based).
/// Mirrors the old _effectivePhase logic: trigger at (i + 1) % interval == 0,
/// which replicates the 1-based cycle % interval == 0 semantics.
List<PhaseSpec> _buildCycleSpec(
  List<BreathingPhase> phases,
  int i,
  int? exhaleInterval,
  int? inhaleInterval,
) {
  final isExtExhaleSpec =
      exhaleInterval != null && (i + 1) % exhaleInterval == 0;
  final isExtInhaleSpec =
      inhaleInterval != null && (i + 1) % inhaleInterval == 0;

  return phases.map((phase) {
    final isExtExhale = isExtExhaleSpec && phase.type == PhaseType.exhale;
    final isExtInhale = isExtInhaleSpec && phase.type == PhaseType.inhale;
    final type = isExtExhale
        ? PhaseType.extendedExhale
        : isExtInhale
            ? PhaseType.extendedInhale
            : phase.type;
      final extraMs = isExtExhale || isExtInhale ? 2000 : 0;
    final ms = phase.duration.inMilliseconds + extraMs;
    return PhaseSpec(
      type: type,
      progression: FixedProgression(Duration(milliseconds: ms)),
    );
  }).toList();
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
int _lcm(int a, int b) => (a * b) ~/ _gcd(a, b);
