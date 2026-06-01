import 'dart:convert';

import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

const _inhale4 = PhaseSpec(
  type: PhaseType.inhale,
  progression: FixedProgression(Duration(seconds: 4)),
);
const _exhale4 = PhaseSpec(
  type: PhaseType.exhale,
  progression: FixedProgression(Duration(seconds: 4)),
);
const _holdIn4 = PhaseSpec(
  type: PhaseType.holdIn,
  progression: FixedProgression(Duration(seconds: 4)),
);
const _holdOut4 = PhaseSpec(
  type: PhaseType.holdOut,
  progression: FixedProgression(Duration(seconds: 4)),
);

const _uniformSegment = SessionSegment(
  label: 'Work',
  cycleCount: 4,
  cycleSpecs: [
    [_inhale4, _holdIn4, _exhale4, _holdOut4],
  ],
);

const _alternatingSegment = SessionSegment(
  label: 'Alt',
  cycleCount: 6,
  cycleSpecs: [
    [_inhale4, _exhale4], // template A (normal)
    [
      _inhale4,
      PhaseSpec(
        type: PhaseType.extendedExhale,
        progression: FixedProgression(Duration(seconds: 6)),
      ),
    ], // template B (extended exhale)
  ],
);

// ── PhaseSpec ────────────────────────────────────────────────────────────────

void main() {
  group('PhaseSpec', () {
    test('JSON round-trip', () {
      final json = _inhale4.toJson();
      expect(json['type'], 'inhale');
      expect(PhaseSpec.fromJson(json), _inhale4);
    });

    test('JSON round-trip for extended types', () {
      const spec = PhaseSpec(
        type: PhaseType.extendedExhale,
        progression: FixedProgression(Duration(seconds: 6)),
      );
      expect(PhaseSpec.fromJson(spec.toJson()), spec);
    });
  });

  // ── SessionSegment ─────────────────────────────────────────────────────────

  group('SessionSegment', () {
    test('phasesForCycle returns uniform spec for single cycleSpec', () {
      expect(_uniformSegment.phasesForCycle(0), _uniformSegment.cycleSpecs[0]);
      expect(_uniformSegment.phasesForCycle(3), _uniformSegment.cycleSpecs[0]);
    });

    test('phasesForCycle wraps with modulo for alternating specs', () {
      final specs = _alternatingSegment.cycleSpecs;
      expect(_alternatingSegment.phasesForCycle(0), specs[0]);
      expect(_alternatingSegment.phasesForCycle(1), specs[1]);
      expect(_alternatingSegment.phasesForCycle(2), specs[0]);
      expect(_alternatingSegment.phasesForCycle(5), specs[1]);
    });

    test('JSON round-trip', () {
      final json = _uniformSegment.toJson();
      expect(SessionSegment.fromJson(json), _uniformSegment);
    });
  });

  // ── SessionProgram ─────────────────────────────────────────────────────────

  group('SessionProgram', () {
    const program = SessionProgram(
      name: 'Test',
      segments: [_uniformSegment, _alternatingSegment],
    );

    test('totalCycles sums all segments', () {
      expect(program.totalCycles, 10); // 4 + 6
    });

    test('resolve produces the correct cycle count', () {
      final timeline = program.resolve();
      expect(timeline.cycles.length, 10);
    });

    test('resolve carries segment labels through', () {
      final timeline = program.resolve();
      expect(
        timeline.cycles.take(4).map((c) => c.segmentLabel),
        everyElement('Work'),
      );
      expect(
        timeline.cycles.skip(4).map((c) => c.segmentLabel),
        everyElement('Alt'),
      );
    });

    test('resolve applies FixedProgression durations correctly', () {
      final timeline = _uniformSegment.let((s) {
        return SessionProgram(name: 'X', segments: [s]).resolve();
      });
      for (final cycle in timeline.cycles) {
        expect(cycle.phases.length, 4);
        for (final phase in cycle.phases) {
          expect(phase.duration, const Duration(seconds: 4));
        }
      }
    });

    test('resolve applies LinearProgression per cycle', () {
      const seg = SessionSegment(
        label: 'Linear',
        cycleCount: 4,
        cycleSpecs: [
          [
            PhaseSpec(
              type: PhaseType.inhale,
              progression: LinearProgression(
                start: Duration(seconds: 4),
                step: Duration(milliseconds: 500),
                max: Duration(seconds: 6),
              ),
            ),
          ],
        ],
      );
      final timeline = const SessionProgram(
        name: 'L',
        segments: [seg],
      ).resolve();
      expect(
        timeline.cycles[0].phases[0].duration,
        const Duration(milliseconds: 4000),
      );
      expect(
        timeline.cycles[1].phases[0].duration,
        const Duration(milliseconds: 4500),
      );
      expect(
        timeline.cycles[2].phases[0].duration,
        const Duration(milliseconds: 5000),
      );
      expect(
        timeline.cycles[3].phases[0].duration,
        const Duration(milliseconds: 5500),
      );
    });

    test('resolve alternates cycleSpecs via modulo', () {
      final timeline = const SessionProgram(
        name: 'Alt',
        segments: [_alternatingSegment],
      ).resolve();
      // Even cycles (0,2,4): template A → exhale type
      expect(timeline.cycles[0].phases[1].type, PhaseType.exhale);
      // Odd cycles (1,3,5): template B → extendedExhale type
      expect(timeline.cycles[1].phases[1].type, PhaseType.extendedExhale);
      expect(timeline.cycles[3].phases[1].type, PhaseType.extendedExhale);
    });

    test('JSON round-trip', () {
      final json = program.toJson();
      // Serialize / deserialize via jsonEncode+jsonDecode to mimic persistence.
      final decoded = SessionProgram.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(decoded, program);
    });
  });

  // ── ResolvedTimeline ───────────────────────────────────────────────────────

  group('ResolvedTimeline', () {
    test('totalSeconds sums all phase durations across all cycles', () {
      // 4 cycles × 4 phases × 4 s = 64 s
      final timeline = const SessionProgram(
        name: 'T',
        segments: [_uniformSegment],
      ).resolve();
      expect(timeline.totalSeconds, 64);
    });
  });
}

// Helper to avoid repeating the SessionProgram(...).resolve() pattern.
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
