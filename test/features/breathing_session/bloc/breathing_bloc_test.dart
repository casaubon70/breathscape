import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pattern = BreathingPattern(
    name: 'Box Breathing',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdIn, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.holdOut, duration: Duration(seconds: 4)),
    ],
  );

  group('BreathingBloc – Play/Pause (Scheibe 2)', () {
    late BreathingBloc bloc;

    setUp(() => bloc = BreathingBloc(pattern: pattern));
    tearDown(() => bloc.close());

    test('initial state is idle with fillLevel 0.0', () {
      expect(bloc.state.status, SessionStatus.idle);
      expect(bloc.state.fillLevel, 0.0);
      expect(bloc.state.currentPhase, PhaseType.inhale);
      expect(bloc.state.currentCycle, 1);
    });

    blocTest<BreathingBloc, BreathingState>(
      'PlayPressed from idle → playing',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc.add(const PlayPressed()),
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.status,
          'status',
          SessionStatus.playing,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PausePressed while playing → paused',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed()),
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.status,
          'status',
          SessionStatus.playing,
        ),
        isA<BreathingState>().having(
          (s) => s.status,
          'status',
          SessionStatus.paused,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PlayPressed from paused → playing',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed())
        ..add(const PlayPressed()),
      skip: 2,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.status,
          'status',
          SessionStatus.playing,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PausePressed while idle → no state change',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc.add(const PausePressed()),
      expect: () => <BreathingState>[],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted advances phase: inhale → holdIn',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()),
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdIn,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted cycles through all four phases',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // holdIn
        ..add(const PhaseCompleted()) // exhale
        ..add(const PhaseCompleted()) // holdOut
        ..add(const PhaseCompleted()), // inhale again
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdIn,
        ),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdOut,
        ),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted while paused → no state change',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed())
        ..add(const PhaseCompleted()),
      skip: 2,
      expect: () => <BreathingState>[],
    );
  });

  group('BreathingBloc – Cycle-Completion', () {
    const singleCyclePattern = BreathingPattern(
      name: 'Single Cycle',
      defaultCycles: 1,
      phases: [
        BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
        BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'nach defaultCycles via PhaseCompleted → status completed, fillLevel 0',
      build: () => BreathingBloc(pattern: singleCyclePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale
        ..add(const PhaseCompleted()), // würde inhale starten → completed
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.completed)
            .having((s) => s.fillLevel, 'fillLevel', 0.0),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'nach defaultCycles via Tick → status completed, fillLevel 0',
      build: () => BreathingBloc(pattern: singleCyclePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale
        ..add(const BreathingTickUpdated(Duration(seconds: 4))), // → completed
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.completed)
            .having((s) => s.fillLevel, 'fillLevel', 0.0),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'ResetPressed aus completed → idle, Zyklus 1',
      build: () => BreathingBloc(pattern: singleCyclePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted())
        ..add(const PhaseCompleted()) // completed
        ..add(const ResetPressed()),
      skip: 3,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.idle)
            .having((s) => s.currentCycle, 'cycle', 1),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'mit defaultCycles 2 läuft zweiter Zyklus noch durch',
      build: () => BreathingBloc(
        pattern: const BreathingPattern(
          name: 'Two Cycles',
          defaultCycles: 2,
          phases: [
            BreathingPhase(
              type: PhaseType.inhale,
              duration: Duration(seconds: 4),
            ),
            BreathingPhase(
              type: PhaseType.exhale,
              duration: Duration(seconds: 4),
            ),
          ],
        ),
      ),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale cycle 1
        ..add(const PhaseCompleted()) // inhale cycle 2
        ..add(const PhaseCompleted()) // exhale cycle 2
        ..add(const PhaseCompleted()), // → completed
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.completed)
            .having((s) => s.fillLevel, 'fillLevel', 0.0),
      ],
    );
  });

  group('BreathingBloc – Ticker-Logik (Scheibe 4)', () {
    blocTest<BreathingBloc, BreathingState>(
      'Tick mit halbem Delta → fillLevel 0.5 (Inhale-Phase)',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 2))),
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.5, 0.001))
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'Tick mit vollem Delta → Phase wechselt zu holdIn, fillLevel 1.0',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))),
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn)
            .having((s) => s.fillLevel, 'fillLevel', 1.0),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'holdIn-Phase: fillLevel bleibt 1.0, circleScale nimmt ab',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → holdIn
        ..add(const BreathingTickUpdated(Duration(seconds: 2))), // 50% holdIn
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn)
            .having((s) => s.fillLevel, 'fillLevel', 1.0)
            .having((s) => s.circleScale, 'circleScale', 1.0),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn)
            .having((s) => s.fillLevel, 'fillLevel', 1.0)
            .having((s) => s.circleScale, 'circleScale', closeTo(0.5, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'exhale-Phase: fillLevel fällt von 1.0 auf 0.0',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → holdIn
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale
        ..add(const BreathingTickUpdated(Duration(seconds: 2))), // 50% exhale
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdIn,
        ),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.fillLevel, 'fillLevel', 1.0),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.5, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'ein vollständiger Zyklus → currentCycle 2, zurück in inhale',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → holdIn
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → holdOut
        ..add(const BreathingTickUpdated(Duration(seconds: 4))), // → inhale
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdIn,
        ),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.holdOut,
        ),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'Tick während Pause → kein State-Update',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 2))),
      skip: 2,
      expect: () => <BreathingState>[],
    );

    blocTest<BreathingBloc, BreathingState>(
      'ResetPressed → Initialzustand, Zyklus 1, Phase inhale',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → holdIn
        ..add(const ResetPressed()),
      skip: 2,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.idle)
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.fillLevel, 'fillLevel', 0.0)
            .having((s) => s.currentCycle, 'cycle', 1),
      ],
    );
  });
}
