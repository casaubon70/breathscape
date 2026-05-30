import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/core/sync/synced_key_value_store.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStore implements SyncedKeyValueStore {
  String? _value;
  final _controller = StreamController<String>.broadcast();

  @override
  Future<String?> read(String key) async => _value;

  @override
  Future<void> write(String key, String value) async => _value = value;

  @override
  Stream<String> watch(String key) => _controller.stream;
}

const _box = BreathingPattern(
  name: 'Box Breathing',
  phases: [
    BreathingPhase(type: PhaseType.inhale, duration: Duration(seconds: 4)),
    BreathingPhase(type: PhaseType.exhale, duration: Duration(seconds: 4)),
  ],
);

Future<List<BreathingPattern>> _baseLoader() async => const [_box];

void main() {
  const fixedNow = 1000;

  PatternsBloc buildBloc({PatternOverridesRepository? repository}) =>
      PatternsBloc(
        overridesRepository:
            repository ?? PatternOverridesRepository(local: FakeStore()),
        baseLoader: _baseLoader,
        now: () => fixedNow,
      );

  group('PatternsBloc', () {
    blocTest<PatternsBloc, PatternsState>(
      'emits [loading, ready] with merged patterns on PatternsLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(const PatternsLoaded()),
      expect: () => [
        const PatternsState(status: PatternsStatus.loading),
        const PatternsState(status: PatternsStatus.ready, patterns: [_box]),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'PhaseSecondsEdited applies the override to the merged patterns',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PatternsLoaded());
        await bloc.stream.firstWhere((s) => s.status == PatternsStatus.ready);
        bloc.add(
          const PhaseSecondsEdited(
            patternName: 'Box Breathing',
            phaseIndex: 0,
            seconds: 7,
          ),
        );
      },
      skip: 2,
      expect: () => [
        const PatternsState(
          status: PatternsStatus.ready,
          patterns: [
            BreathingPattern(
              name: 'Box Breathing',
              phases: [
                BreathingPhase(
                  type: PhaseType.inhale,
                  duration: Duration(seconds: 7),
                ),
                BreathingPhase(
                  type: PhaseType.exhale,
                  duration: Duration(seconds: 4),
                ),
              ],
            ),
          ],
          overrides: PatternOverrides(
            byPattern: {
              'Box Breathing': {0: 7},
            },
            updatedAt: fixedNow,
          ),
        ),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'PhaseSecondsEdited clamps seconds to the max',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PatternsLoaded());
        await bloc.stream.firstWhere((s) => s.status == PatternsStatus.ready);
        bloc.add(
          const PhaseSecondsEdited(
            patternName: 'Box Breathing',
            phaseIndex: 0,
            seconds: 500,
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<PatternsState>().having(
          (s) => s.overrides.byPattern['Box Breathing']?[0],
          'clamped seconds',
          PatternsBloc.maxSeconds,
        ),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'PatternReset removes the overrides for a pattern',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PatternsLoaded());
        await bloc.stream.firstWhere((s) => s.status == PatternsStatus.ready);
        bloc
          ..add(
            const PhaseSecondsEdited(
              patternName: 'Box Breathing',
              phaseIndex: 0,
              seconds: 7,
            ),
          )
          ..add(const PatternReset('Box Breathing'));
      },
      skip: 3,
      expect: () => [
        isA<PatternsState>()
            .having((s) => s.overrides.isEmpty, 'overrides cleared', true)
            .having((s) => s.patterns, 'patterns back to base', const [_box]),
      ],
    );

    blocTest<PatternsBloc, PatternsState>(
      'RemoteOverridesReceived re-merges without saving',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PatternsLoaded());
        await bloc.stream.firstWhere((s) => s.status == PatternsStatus.ready);
        bloc.add(
          const RemoteOverridesReceived(
            PatternOverrides(
              byPattern: {
                'Box Breathing': {1: 9},
              },
              updatedAt: 5000,
            ),
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<PatternsState>().having(
          (s) => s.patterns.single.phases[1].duration.inSeconds,
          'remote exhale seconds applied',
          9,
        ),
      ],
    );
  });
}
