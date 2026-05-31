import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_migration.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter_test/flutter_test.dart';

final _boxProgram = migratePatternToProgram(
  const BreathingPattern(
    name: 'Box Breathing',
    phases: [
      BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
      BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
    ],
  ),
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
        PatternsState(status: PatternsStatus.ready, programs: [_boxProgram]),
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
