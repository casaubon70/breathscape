import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';

const _box = BreathingPattern(
  name: 'Box Breathing',
  phases: [
    BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
    BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
  ],
);

Future<List<BreathingPattern>> _baseLoader() async => const [_box];

void main() {
  group('PatternsBloc', () {
    blocTest<PatternsBloc, PatternsState>(
      'emits [loading, ready] with patterns on PatternsLoaded',
      build: () => PatternsBloc(baseLoader: _baseLoader),
      act: (bloc) => bloc.add(const PatternsLoaded()),
      expect: () => [
        const PatternsState(status: PatternsStatus.loading),
        const PatternsState(status: PatternsStatus.ready, patterns: [_box]),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'emits [loading, failure] when loader throws',
      build: () => PatternsBloc(
        baseLoader: () async => throw Exception('load failed'),
      ),
      act: (bloc) => bloc.add(const PatternsLoaded()),
      expect: () => [
        const PatternsState(status: PatternsStatus.loading),
        const PatternsState(status: PatternsStatus.failure),
      ],
    );
  });
}
