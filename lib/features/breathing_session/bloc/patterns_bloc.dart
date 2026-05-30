import 'dart:async';

import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides_repository.dart';
import 'package:breathscape/features/breathing_session/domain/patterns_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the list of breathing patterns with user overrides applied, and
/// handles editing of per-phase durations.
class PatternsBloc extends Bloc<PatternsEvent, PatternsState> {
  PatternsBloc({
    required PatternOverridesRepository overridesRepository,
    Future<List<BreathingPattern>> Function()? baseLoader,
    int Function()? now,
  }) : _overridesRepository = overridesRepository,
       _baseLoader = baseLoader ?? PatternsRepository.load,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
       super(const PatternsState()) {
    on<PatternsLoaded>(_onLoaded);
    on<PhaseSecondsEdited>(_onPhaseSecondsEdited);
    on<PatternReset>(_onPatternReset);
    on<RemoteOverridesReceived>(_onRemoteOverridesReceived);
  }

  /// Minimum and maximum editable duration for a single phase, in seconds.
  static const int minSeconds = kMinPhaseDurationSeconds;
  static const int maxSeconds = kMaxPhaseDurationSeconds;

  final PatternOverridesRepository _overridesRepository;
  final Future<List<BreathingPattern>> Function() _baseLoader;
  final int Function() _now;

  List<BreathingPattern> _base = const [];
  StreamSubscription<PatternOverrides>? _remoteSubscription;

  @override
  Future<void> close() {
    _remoteSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoaded(
    PatternsLoaded event,
    Emitter<PatternsState> emit,
  ) async {
    emit(state.copyWith(status: PatternsStatus.loading));
    try {
      _base = await _baseLoader();
      final overrides = await _overridesRepository.load();
      emit(
        state.copyWith(
          status: PatternsStatus.ready,
          patterns: applyOverrides(_base, overrides),
          overrides: overrides,
        ),
      );
      _remoteSubscription ??= _overridesRepository.changes.listen(
        (remote) => add(RemoteOverridesReceived(remote)),
      );
    } on Exception {
      emit(state.copyWith(status: PatternsStatus.failure));
    }
  }

  Future<void> _onPhaseSecondsEdited(
    PhaseSecondsEdited event,
    Emitter<PatternsState> emit,
  ) async {
    final clamped = event.seconds.clamp(minSeconds, maxSeconds);
    final overrides = state.overrides.withPhaseSeconds(
      event.patternName,
      event.phaseIndex,
      clamped,
      updatedAt: _now(),
    );
    await _persistAndEmit(overrides, emit);
  }

  Future<void> _onPatternReset(
    PatternReset event,
    Emitter<PatternsState> emit,
  ) async {
    final overrides = state.overrides.withoutPattern(
      event.patternName,
      updatedAt: _now(),
    );
    await _persistAndEmit(overrides, emit);
  }

  void _onRemoteOverridesReceived(
    RemoteOverridesReceived event,
    Emitter<PatternsState> emit,
  ) {
    // The repository already wrote the remote copy through to local storage,
    // so only re-merge here — no save.
    emit(
      state.copyWith(
        patterns: applyOverrides(_base, event.overrides),
        overrides: event.overrides,
      ),
    );
  }

  Future<void> _persistAndEmit(
    PatternOverrides overrides,
    Emitter<PatternsState> emit,
  ) async {
    await _overridesRepository.save(overrides);
    emit(
      state.copyWith(
        patterns: applyOverrides(_base, overrides),
        overrides: overrides,
      ),
    );
  }
}
