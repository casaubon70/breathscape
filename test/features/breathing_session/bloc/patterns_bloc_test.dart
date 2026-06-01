import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter_test/flutter_test.dart';

const _boxProgram = SessionProgram(
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
            type: PhaseType.exhale,
            progression: FixedProgression(Duration(seconds: 4)),
          ),
        ],
      ],
    ),
  ],
);

Future<List<SessionProgram>> _baseLoader() async => [_boxProgram];

void main() {
  group('PatternsBloc', () {
    blocTest<PatternsBloc, PatternsState>(
      'emits [loading, ready] with programs on PatternsLoaded',
      build: () => PatternsBloc(programsLoader: _baseLoader),
      act: (bloc) => bloc.add(const PatternsLoaded()),
      expect: () => [
        const PatternsState(status: PatternsStatus.loading),
        const PatternsState(
          status: PatternsStatus.ready,
          programs: [_boxProgram],
        ),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'emits [loading, failure] when loader throws',
      build: () => PatternsBloc(
        programsLoader: () async => throw Exception('load failed'),
      ),
      act: (bloc) => bloc.add(const PatternsLoaded()),
      expect: () => [
        const PatternsState(status: PatternsStatus.loading),
        const PatternsState(status: PatternsStatus.failure),
      ],
    );
  });
}
