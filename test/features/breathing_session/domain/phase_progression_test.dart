import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FixedProgression', () {
    const prog = FixedProgression(Duration(seconds: 4));

    test('durationFor always returns the fixed duration', () {
      expect(prog.durationFor(0), const Duration(seconds: 4));
      expect(prog.durationFor(5), const Duration(seconds: 4));
      expect(prog.durationFor(99), const Duration(seconds: 4));
    });

    test('JSON round-trip – integer seconds', () {
      final json = prog.toJson();
      expect(json['kind'], 'fixed');
      expect(json['seconds'], 4.0);
      expect(FixedProgression.fromJson(json), prog);
    });

    test('JSON round-trip – sub-second precision', () {
      const half = FixedProgression(Duration(milliseconds: 500));
      final json = half.toJson();
      expect(json['seconds'], 0.5);
      expect(FixedProgression.fromJson(json), half);
    });

    test('PhaseProgression.fromJson dispatches correctly', () {
      final result = PhaseProgression.fromJson(
        const {'kind': 'fixed', 'seconds': 4},
      );
      expect(result, isA<FixedProgression>());
    });
  });

  group('LinearProgression', () {
    const prog = LinearProgression(
      start: Duration(seconds: 4),
      step: Duration(milliseconds: 500),
      max: Duration(seconds: 6),
    );

    test('durationFor increases by step each cycle', () {
      expect(prog.durationFor(0), const Duration(milliseconds: 4000));
      expect(prog.durationFor(1), const Duration(milliseconds: 4500));
      expect(prog.durationFor(2), const Duration(milliseconds: 5000));
    });

    test('durationFor clamps at max', () {
      // After 4 steps: 4000 + 4 * 500 = 6000 = max
      expect(prog.durationFor(4), const Duration(seconds: 6));
      // Would exceed max without clamping
      expect(prog.durationFor(10), const Duration(seconds: 6));
    });

    test('durationFor clamps at min for decreasing progression', () {
      const dec = LinearProgression(
        start: Duration(seconds: 6),
        step: Duration(milliseconds: -500),
        min: Duration(seconds: 4),
      );
      expect(dec.durationFor(0), const Duration(seconds: 6));
      expect(dec.durationFor(4), const Duration(seconds: 4));
      expect(dec.durationFor(10), const Duration(seconds: 4));
    });

    test('JSON round-trip with max bound', () {
      final json = prog.toJson();
      expect(json['kind'], 'linear');
      expect(json['startSeconds'], 4.0);
      expect(json['stepSeconds'], 0.5);
      expect(json['maxSeconds'], 6.0);
      expect(json.containsKey('minSeconds'), isFalse);
      expect(LinearProgression.fromJson(json), prog);
    });

    test('JSON round-trip without bounds', () {
      const unbounded = LinearProgression(
        start: Duration(seconds: 2),
        step: Duration(seconds: 1),
      );
      final json = unbounded.toJson();
      expect(json.containsKey('maxSeconds'), isFalse);
      expect(json.containsKey('minSeconds'), isFalse);
      expect(LinearProgression.fromJson(json), unbounded);
    });

    test('PhaseProgression.fromJson dispatches correctly', () {
      final result = PhaseProgression.fromJson(const {
        'kind': 'linear',
        'startSeconds': 4,
        'stepSeconds': 0.5,
        'maxSeconds': 6,
      });
      expect(result, isA<LinearProgression>());
    });
  });

  group('StepProgression', () {
    const prog = StepProgression([
      Duration(seconds: 4),
      Duration(seconds: 5),
      Duration(seconds: 6),
    ]);

    test('durationFor returns the value at the cycle index', () {
      expect(prog.durationFor(0), const Duration(seconds: 4));
      expect(prog.durationFor(1), const Duration(seconds: 5));
      expect(prog.durationFor(2), const Duration(seconds: 6));
    });

    test('durationFor clamps at last value for out-of-range cycles', () {
      expect(prog.durationFor(3), const Duration(seconds: 6));
      expect(prog.durationFor(99), const Duration(seconds: 6));
    });

    test('JSON round-trip', () {
      final json = prog.toJson();
      expect(json['kind'], 'steps');
      expect(json['seconds'], [4.0, 5.0, 6.0]);
      expect(StepProgression.fromJson(json), prog);
    });

    test('PhaseProgression.fromJson dispatches correctly', () {
      final result = PhaseProgression.fromJson(const {
        'kind': 'steps',
        'seconds': [4, 5],
      });
      expect(result, isA<StepProgression>());
    });
  });

  group('PhaseProgression.fromJson', () {
    test('throws for unknown kind', () {
      expect(
        () => PhaseProgression.fromJson(const {'kind': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
