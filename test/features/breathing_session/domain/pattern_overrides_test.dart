import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boxBreathing = BreathingPattern(
    name: 'Box Breathing',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdIn, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdOut, duration: Duration(seconds: 4)),
    ],
    extendedExhaleInterval: 3,
  );

  group('PatternOverrides', () {
    test('toJson/fromJson round-trip preserves data', () {
      const overrides = PatternOverrides(
        byPattern: {
          'Box Breathing': {0: 5, 2: 6},
          '4-7-8 Breathing': {1: 8},
        },
        updatedAt: 1730000000000,
      );

      final restored = PatternOverrides.fromJson(overrides.toJson());

      expect(restored, overrides);
    });

    test('fromJson tolerates missing fields', () {
      final overrides = PatternOverrides.fromJson(const {});

      expect(overrides.isEmpty, isTrue);
      expect(overrides.updatedAt, 0);
    });

    test('withPhaseSeconds adds an override without mutating the original', () {
      const original = PatternOverrides();

      final updated = original.withPhaseSeconds(
        'Box Breathing',
        0,
        7,
        updatedAt: 123,
      );

      expect(original.isEmpty, isTrue);
      expect(updated.byPattern['Box Breathing'], {0: 7});
      expect(updated.updatedAt, 123);
    });

    test('withoutPattern removes a pattern entry', () {
      const original = PatternOverrides(
        byPattern: {
          'Box Breathing': {0: 7},
          '4-7-8 Breathing': {1: 8},
        },
      );

      final updated = original.withoutPattern('Box Breathing', updatedAt: 9);

      expect(updated.byPattern.containsKey('Box Breathing'), isFalse);
      expect(updated.byPattern['4-7-8 Breathing'], {1: 8});
      expect(updated.updatedAt, 9);
    });
  });

  group('applyOverrides', () {
    test('empty overrides return the base list unchanged', () {
      final base = [boxBreathing];

      final result = applyOverrides(base, const PatternOverrides());

      expect(result, same(base));
    });

    test('replaces only the overridden phase durations by index', () {
      final result = applyOverrides(
        [boxBreathing],
        const PatternOverrides(
          byPattern: {
            'Box Breathing': {0: 6, 2: 8},
          },
        ),
      );

      final phases = result.single.phases;
      expect(phases[0].duration, const Duration(seconds: 6));
      expect(phases[1].duration, const Duration(seconds: 4));
      expect(phases[2].duration, const Duration(seconds: 8));
      expect(phases[3].duration, const Duration(seconds: 4));
    });

    test('preserves phase types and pattern metadata', () {
      final result = applyOverrides(
        [boxBreathing],
        const PatternOverrides(
          byPattern: {
            'Box Breathing': {0: 6},
          },
        ),
      );

      final pattern = result.single;
      expect(pattern.phases.map((p) => p.type), [
        PhaseType.inhale,
        PhaseType.holdIn,
        PhaseType.exhale,
        PhaseType.holdOut,
      ]);
      expect(pattern.extendedExhaleInterval, 3);
      expect(pattern.defaultCycles, 10);
    });

    test('leaves patterns without overrides untouched', () {
      final result = applyOverrides(
        [boxBreathing],
        const PatternOverrides(
          byPattern: {
            'Other Pattern': {0: 9},
          },
        ),
      );

      expect(result.single, boxBreathing);
    });
  });
}
