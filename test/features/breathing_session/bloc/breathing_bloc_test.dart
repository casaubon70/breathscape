import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/presentation/patterns/patterns_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pattern = PatternsData.boxBreathing; // 4s pro Phase

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
      act: (bloc) => bloc.add(PlayPressed()),
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.playing),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PausePressed while playing → paused',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PausePressed());
      },
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.playing),
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.paused),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PlayPressed from paused → playing',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PausePressed());
        bloc.add(PlayPressed());
      },
      skip: 2,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', SessionStatus.playing),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PausePressed while idle → no state change',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) => bloc.add(PausePressed()),
      expect: () => [],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted advances phase: inhale → holdIn',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PhaseCompleted());
      },
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted cycles through all four phases',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PhaseCompleted()); // holdIn
        bloc.add(PhaseCompleted()); // exhale
        bloc.add(PhaseCompleted()); // holdOut
        bloc.add(PhaseCompleted()); // inhale again
      },
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdOut),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted while paused → no state change',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PausePressed());
        bloc.add(PhaseCompleted());
      },
      skip: 2,
      expect: () => [],
    );
  });

  group('BreathingBloc – Ticker-Logik (Scheibe 4)', () {
    blocTest<BreathingBloc, BreathingState>(
      'Tick mit halbem Delta → fillLevel 0.5 (Inhale-Phase)',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 2)));
      },
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
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4)));
      },
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
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → holdIn
        bloc.add(const BreathingTickUpdated(Duration(seconds: 2))); // 50% holdIn
      },
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
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → holdIn
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → exhale
        bloc.add(const BreathingTickUpdated(Duration(seconds: 2))); // 50% exhale
      },
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn),
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
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → holdIn
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → exhale
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → holdOut
        bloc.add(const BreathingTickUpdated(Duration(seconds: 4))); // → inhale
      },
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdIn),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.holdOut),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'Tick während Pause → kein State-Update',
      build: () => BreathingBloc(pattern: pattern),
      act: (bloc) {
        bloc.add(PlayPressed());
        bloc.add(PausePressed());
        bloc.add(const BreathingTickUpdated(Duration(seconds: 2)));
      },
      skip: 2,
      expect: () => [],
    );
  });
}
