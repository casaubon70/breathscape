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

const _workSegment = SessionSegment(
  label: 'Work',
  cycleCount: 4,
  cycleSpec: [_inhale4, _holdIn4, _exhale4, _holdOut4],
);

const _cooldownSegment = SessionSegment(
  label: 'Cool-down',
  cycleCount: 6,
  cycleSpec: [_inhale4, _exhale4],
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
    test('JSON round-trip', () {
      final json = _workSegment.toJson();
      expect(SessionSegment.fromJson(json), _workSegment);
    });
  });

  // ── SessionProgram ─────────────────────────────────────────────────────────

  group('SessionProgram', () {
    const program = SessionProgram(
      name: 'Test',
      segments: [_workSegment, _cooldownSegment],
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
        everyElement('Cool-down'),
      );
    });

    test('resolve applies FixedProgression durations correctly', () {
      final timeline = const SessionProgram(
        name: 'X',
        segments: [_workSegment],
      ).resolve();
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
        cycleSpec: [
          PhaseSpec(
            type: PhaseType.inhale,
            progression: LinearProgression(
              start: Duration(seconds: 4),
              step: Duration(milliseconds: 500),
              max: Duration(seconds: 6),
            ),
          ),
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
        segments: [_workSegment],
      ).resolve();
      expect(timeline.totalSeconds, 64);
    });
  });
}
