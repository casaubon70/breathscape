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

    test('fromJson reads interval', () {
      final spec = PhaseSpec.fromJson(const {
        'type': 'extended_exhale',
        'progression': {'kind': 'fixed', 'seconds': 8},
        'interval': 5,
      });
      expect(spec.interval, 5);
    });

    test('toJson omits null interval', () {
      expect(_inhale4.toJson().containsKey('interval'), isFalse);
    });

    test('toJson includes set interval and round-trips', () {
      const spec = PhaseSpec(
        type: PhaseType.extendedExhale,
        progression: FixedProgression(Duration(seconds: 8)),
        interval: 5,
      );
      expect(spec.toJson()['interval'], 5);
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

  // ── interval phases ────────────────────────────────────────────────────────

  group('interval phases', () {
    const inhale4 = PhaseSpec(
      type: PhaseType.inhale,
      progression: FixedProgression(Duration(seconds: 4)),
    );
    const exhale6 = PhaseSpec(
      type: PhaseType.exhale,
      progression: FixedProgression(Duration(seconds: 6)),
    );
    const extExhale8interval5 = PhaseSpec(
      type: PhaseType.extendedExhale,
      progression: FixedProgression(Duration(seconds: 8)),
      interval: 5,
    );

    SessionProgram makeProgram(int cycleCount) => SessionProgram(
      name: 'Test',
      segments: [
        SessionSegment(
          label: 'Seg',
          cycleCount: cycleCount,
          cycleSpec: const [inhale4, exhale6, extExhale8interval5],
        ),
      ],
    );

    test('non-interval cycles contain inhale + exhale', () {
      final timeline = makeProgram(11).resolve();
      for (final i in [1, 2, 3, 4, 6, 7, 8, 9]) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale, PhaseType.exhale]);
      }
    });

    test('interval cycles (1, 6, 11) contain inhale + extendedExhale', () {
      final timeline = makeProgram(11).resolve();
      for (final i in [0, 5, 10]) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale, PhaseType.extendedExhale]);
      }
    });

    // interval=5, cycleCount=3: only cycle 1 (index 0) is extended
    test('first cycle extended, rest normal if cycleCount < 2*interval', () {
      final timeline = makeProgram(3).resolve();
      final firstTypes = timeline.cycles[0].phases.map((p) => p.type).toList();
      expect(firstTypes, [PhaseType.inhale, PhaseType.extendedExhale]);
      for (final i in [1, 2]) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale, PhaseType.exhale]);
      }
    });

    test('interval:1 means every cycle is extended', () {
      const seg = SessionSegment(
        label: 'S',
        cycleCount: 4,
        cycleSpec: [
          inhale4,
          exhale6,
          PhaseSpec(
            type: PhaseType.extendedExhale,
            progression: FixedProgression(Duration(seconds: 8)),
            interval: 1,
          ),
        ],
      );
      final timeline = const SessionProgram(
        name: 'T',
        segments: [seg],
      ).resolve();
      for (final cycle in timeline.cycles) {
        final types = cycle.phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale, PhaseType.extendedExhale]);
      }
    });

    test('extended fires alone when no base phase in spec', () {
      const seg = SessionSegment(
        label: 'S',
        cycleCount: 5,
        cycleSpec: [inhale4, extExhale8interval5],
      );
      final timeline = const SessionProgram(
        name: 'T',
        segments: [seg],
      ).resolve();
      final firstTypes = timeline.cycles[0].phases.map((p) => p.type).toList();
      expect(firstTypes, [PhaseType.inhale, PhaseType.extendedExhale]);
      for (var i = 1; i < 5; i++) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale]);
      }
    });

    test('extended_inhale replaces inhale symmetrically', () {
      const seg = SessionSegment(
        label: 'S',
        cycleCount: 6,
        cycleSpec: [
          PhaseSpec(
            type: PhaseType.inhale,
            progression: FixedProgression(Duration(seconds: 4)),
          ),
          PhaseSpec(
            type: PhaseType.extendedInhale,
            progression: FixedProgression(Duration(seconds: 6)),
            interval: 3,
          ),
          exhale6,
        ],
      );
      final timeline = const SessionProgram(
        name: 'T',
        segments: [seg],
      ).resolve();
      for (final i in [1, 2, 4, 5]) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.inhale, PhaseType.exhale]);
      }
      for (final i in [0, 3]) {
        final types = timeline.cycles[i].phases.map((p) => p.type).toList();
        expect(types, [PhaseType.extendedInhale, PhaseType.exhale]);
      }
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
