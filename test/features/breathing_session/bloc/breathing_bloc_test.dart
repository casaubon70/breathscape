import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter_test/flutter_test.dart';

BreathingBloc _bloc(SessionProgram p) => BreathingBloc(program: p);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pattern = SessionProgram(
    name: 'Box Breathing',
    segments: [
      SessionSegment(
        label: 'Box Breathing',
        cycleCount: 10,
        cycleSpecs: [
          [
            PhaseSpec(
              type: PhaseType.inhale,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
            PhaseSpec(
              type: PhaseType.holdIn,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
            PhaseSpec(
              type: PhaseType.exhale,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
            PhaseSpec(
              type: PhaseType.holdOut,
              progression: FixedProgression(Duration(seconds: 4)),
            ),
          ],
        ],
      ),
    ],
  );

  group('BreathingBloc – Play/Pause (Scheibe 2)', () {
    late BreathingBloc bloc;

    setUp(() => bloc = _bloc(pattern));
    tearDown(() => bloc.close());

    test('initial state is idle with fillLevel 0.0', () {
      expect(bloc.state.status, SessionStatus.idle);
      expect(bloc.state.fillLevel, 0.0);
      expect(bloc.state.currentPhase, PhaseType.inhale);
      expect(bloc.state.currentCycle, 1);
    });

    blocTest<BreathingBloc, BreathingState>(
      'PlayPressed from idle → playing',
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
      act: (bloc) => bloc.add(const PausePressed()),
      expect: () => <BreathingState>[],
    );

    blocTest<BreathingBloc, BreathingState>(
      'PhaseCompleted advances phase: inhale → holdIn',
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed())
        ..add(const PhaseCompleted()),
      skip: 2,
      expect: () => <BreathingState>[],
    );
  });

  group('BreathingBloc – Cycle-Completion', () {
    const singleCyclePattern = SessionProgram(
      name: 'Single Cycle',
      segments: [
        SessionSegment(
          label: 'Single Cycle',
          cycleCount: 1,
          cycleSpecs: [
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
          ],
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'nach defaultCycles via PhaseCompleted → status completed, fillLevel 0',
      build: () => _bloc(singleCyclePattern),
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
      build: () => _bloc(singleCyclePattern),
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
      build: () => _bloc(singleCyclePattern),
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
      build: () => _bloc(
        const SessionProgram(
          name: 'Two Cycles',
          segments: [
            SessionSegment(
              label: 'Two Cycles',
              cycleCount: 2,
              cycleSpecs: [
                [
                  PhaseSpec(
                    type: PhaseType.inhale,
                    progression: FixedProgression(Duration(seconds: 4)),
                  ),
                  PhaseSpec(
                    type: PhaseType.exhale,
                    progression: FixedProgression(Duration(seconds: 4)),
                  ),
                ],
              ],
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

  group('BreathingBloc – Extended Exhale', () {
    const extPattern = SessionProgram(
      name: 'Extended Test',
      segments: [
        SessionSegment(
          label: 'Extended Test',
          cycleCount: 6,
          cycleSpecs: [
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.extendedExhale,
                progression: FixedProgression(Duration(seconds: 6)),
              ),
            ],
          ],
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 1: exhale → normal exhale (no extended)',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()), // → exhale on cycle 1
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.isExtendedExhale, 'isExtendedExhale', false)
            .having((s) => s.phaseSecondsRemaining, 'seconds', 4),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3: exhale → extendedExhale with +2 s duration',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()) // inhale c3
        ..add(const PhaseCompleted()), // exhale c3 → should be extended
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ), // c1 exhale
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ), // c2 exhale
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 3),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedExhale)
            .having((s) => s.isExtendedExhale, 'isExtendedExhale', true)
            .having((s) => s.phaseSecondsRemaining, 'seconds', 6),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3 via Tick: middle fills 1→0 at threshold, deep zone fills after',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedExhale c3 (start)
        ..add(
          const BreathingTickUpdated(Duration(seconds: 2)),
        ), // 2/6 s, below 4/6 threshold
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
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 3),
        // phase start: fillLevel 1.0, deepZoneFill 0.0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedExhale)
            .having((s) => s.fillLevel, 'fillLevel', 1.0)
            .having((s) => s.deepZoneFill, 'deepZoneFill', 0.0),
        // 2 s in → progress 2/6 ≈ 0.333, threshold = 0.75
        // fillLevel = 1 - (1/3)/0.75 = 1 - 4/9 ≈ 0.556; deepZoneFill = 0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedExhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.556, 0.001))
            .having((s) => s.deepZoneFill, 'deepZoneFill', closeTo(0.0, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3: deepZoneFill grows after middle zone is empty',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedExhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 5)),
        ), // 5 s in, progress 5/6 > threshold 0.75
      skip: 6, // skip play + 4 phase transitions + extendedExhale start
      expect: () => [
        // 5 s in → progress 5/6 ≈ 0.833, threshold = 0.75
        // fillLevel = 0.0 (clamped); deepZoneFill = (5/6-3/4)/(1/4) = 1/3 ≈ 0.333
        isA<BreathingState>()
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.0, 0.001))
            .having(
              (s) => s.deepZoneFill,
              'deepZoneFill',
              closeTo(0.333, 0.001),
            ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'isExtendedExhale resets to false on next inhale',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()) // inhale c3
        ..add(const PhaseCompleted()) // extendedExhale c3
        ..add(const PhaseCompleted()), // inhale c4
      skip: 6,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.isExtendedExhale, 'isExtendedExhale', false)
            .having((s) => s.currentCycle, 'cycle', 4),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'inhale after deep exhale starts with deepZoneFill=1, fillLevel=0',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()) // inhale c3
        ..add(const PhaseCompleted()) // extendedExhale c3
        ..add(const PhaseCompleted()), // inhale c4 ← starts from deep zone
      skip: 6,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.fillLevel, 'fillLevel', 0.0)
            .having((s) => s.deepZoneFill, 'deepZoneFill', 1.0),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'deep inhale via Tick: lower zone clears first, then middle zone fills',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedExhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 6)),
        ) // → inhale c4 (extendedExhale 6 s done)
        ..add(
          const BreathingTickUpdated(Duration(seconds: 1)),
        ), // 1 s into 4 s inhale → progress 0.25 = threshold
      skip: 7, // skip play + 5 transitions + inhale-c4 start
      expect: () => [
        // At progress=0.25: lower zone just cleared, middle not yet started
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.0, 0.001))
            .having((s) => s.deepZoneFill, 'deepZoneFill', closeTo(0.0, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'deep inhale: at progress=0.625 fillLevel=0.5, deepZoneFill=0',
      build: () => _bloc(extPattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedExhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 6)),
        ) // → inhale c4 (extendedExhale 6 s done)
        ..add(
          const BreathingTickUpdated(Duration(milliseconds: 2500)),
        ), // 2.5 s of 4 s → progress 0.625
      skip: 7, // skip play + 5 transitions + inhale-c4 start
      expect: () => [
        // progress=0.625 → fillLevel = (0.625-0.25)/0.75 = 0.5, deepZoneFill = 0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.5, 0.001))
            .having((s) => s.deepZoneFill, 'deepZoneFill', closeTo(0.0, 0.001)),
      ],
    );
  });

  group('BreathingBloc – Extended Inhale', () {
    const extInhalePattern = SessionProgram(
      name: 'Extended Inhale Test',
      segments: [
        SessionSegment(
          label: 'Extended Inhale Test',
          cycleCount: 6,
          cycleSpecs: [
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
            [
              PhaseSpec(
                type: PhaseType.inhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
            [
              PhaseSpec(
                type: PhaseType.extendedInhale,
                progression: FixedProgression(Duration(seconds: 6)),
              ),
              PhaseSpec(
                type: PhaseType.exhale,
                progression: FixedProgression(Duration(seconds: 4)),
              ),
            ],
          ],
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 1: inhale → normal inhale (no extended)',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // → exhale c1
        ..add(const PhaseCompleted()), // → inhale c2
      skip: 1,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.isExtendedInhale, 'isExtendedInhale', false),
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.isExtendedInhale, 'isExtendedInhale', false)
            .having((s) => s.phaseSecondsRemaining, 'seconds', 4),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3: inhale → extendedInhale with +2 s duration',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()), // inhale c3 → should be extended
      skip: 1,
      expect: () => [
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ), // c1 exhale
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.inhale)
            .having((s) => s.currentCycle, 'cycle', 2),
        isA<BreathingState>().having(
          (s) => s.currentPhase,
          'phase',
          PhaseType.exhale,
        ), // c2 exhale
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedInhale)
            .having((s) => s.isExtendedInhale, 'isExtendedInhale', true)
            .having((s) => s.phaseSecondsRemaining, 'seconds', 6),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3 via Tick: middle fills 0→1 at threshold, top zone fills after',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedInhale c3 (start)
        ..add(
          const BreathingTickUpdated(Duration(seconds: 2)),
        ), // 2/6 s, below 4/6 threshold
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
        // phase start: fillLevel 0.0, topZoneFill 0.0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedInhale)
            .having((s) => s.fillLevel, 'fillLevel', 0.0)
            .having((s) => s.topZoneFill, 'topZoneFill', 0.0),
        // 2 s in → progress 2/6 ≈ 0.333, threshold = 0.75
        // fillLevel = (1/3)/0.75 ≈ 0.444; topZoneFill = 0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.extendedInhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.444, 0.001))
            .having((s) => s.topZoneFill, 'topZoneFill', closeTo(0.0, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'cycle 3: topZoneFill grows after middle zone is full',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedInhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 5)),
        ), // 5 s in, progress 5/6 > threshold 0.75
      skip: 5, // skip play + 3 transitions + extendedInhale start
      expect: () => [
        // 5 s in → progress 5/6 ≈ 0.833, threshold = 0.75
        // fillLevel = 1.0 (clamped); topZoneFill = (5/6-3/4)/(1/4) ≈ 0.333
        isA<BreathingState>()
            .having((s) => s.fillLevel, 'fillLevel', closeTo(1.0, 0.001))
            .having((s) => s.topZoneFill, 'topZoneFill', closeTo(0.333, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'isExtendedInhale resets to false on next exhale',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()) // extendedInhale c3
        ..add(const PhaseCompleted()), // exhale c3
      skip: 5,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.isExtendedInhale, 'isExtendedInhale', false)
            .having((s) => s.currentCycle, 'cycle', 3),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'exhale after deep inhale starts with topZoneFill=1, fillLevel=1',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PhaseCompleted()) // exhale c1
        ..add(const PhaseCompleted()) // inhale c2
        ..add(const PhaseCompleted()) // exhale c2
        ..add(const PhaseCompleted()) // extendedInhale c3
        ..add(const PhaseCompleted()), // exhale c3 ← starts from top zone
      skip: 5,
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.fillLevel, 'fillLevel', 1.0)
            .having((s) => s.topZoneFill, 'topZoneFill', 1.0),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'recovery exhale via Tick: top clears first, then middle empties',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedInhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 6)),
        ) // → exhale c3 (extendedInhale 6 s done)
        ..add(
          const BreathingTickUpdated(Duration(seconds: 1)),
        ), // 1 s into 4 s exhale → progress 0.25 = threshold
      skip: 6, // skip play + 3 transitions + extendedInhale + exhale start
      expect: () => [
        // At progress=0.25: top zone just cleared, middle not yet started
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(1.0, 0.001))
            .having((s) => s.topZoneFill, 'topZoneFill', closeTo(0.0, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'recovery exhale: at progress=0.625 fillLevel=0.5, topZoneFill=0',
      build: () => _bloc(extInhalePattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c1
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → inhale c2
        ..add(const BreathingTickUpdated(Duration(seconds: 4))) // → exhale c2
        ..add(
          const BreathingTickUpdated(Duration(seconds: 4)),
        ) // → extendedInhale c3
        ..add(
          const BreathingTickUpdated(Duration(seconds: 6)),
        ) // → exhale c3 (extendedInhale 6 s done)
        ..add(
          const BreathingTickUpdated(Duration(milliseconds: 2500)),
        ), // 2.5 s of 4 s → progress 0.625
      skip: 6,
      expect: () => [
        // progress=0.625 → fillLevel = 1-(0.625-0.25)/0.75 = 0.5, topZoneFill=0
        isA<BreathingState>()
            .having((s) => s.currentPhase, 'phase', PhaseType.exhale)
            .having((s) => s.fillLevel, 'fillLevel', closeTo(0.5, 0.001))
            .having((s) => s.topZoneFill, 'topZoneFill', closeTo(0.0, 0.001)),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'session seconds includes +2 s on deep-inhale cycles',
      build: () => _bloc(extInhalePattern),
      act: (bloc) {},
      expect: () => <BreathingState>[],
      verify: (bloc) {
        // 6 cycles × (inhale 4 s + exhale 4 s) = 48 s
        // +2 s on cycles 3 and 6 (extendedInhaleInterval=3) = 52 s
        expect(bloc.state.sessionSecondsRemaining, 52);
      },
    );
  });

  group('BreathingBloc – Ticker-Logik (Scheibe 4)', () {
    blocTest<BreathingBloc, BreathingState>(
      'Tick mit halbem Delta → fillLevel 0.5 (Inhale-Phase)',
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
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
      build: () => _bloc(pattern),
      act: (bloc) => bloc
        ..add(const PlayPressed())
        ..add(const PausePressed())
        ..add(const BreathingTickUpdated(Duration(seconds: 2))),
      skip: 2,
      expect: () => <BreathingState>[],
    );

    blocTest<BreathingBloc, BreathingState>(
      'ResetPressed → Initialzustand, Zyklus 1, Phase inhale',
      build: () => _bloc(pattern),
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
