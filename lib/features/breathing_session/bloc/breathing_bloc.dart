import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/resolved_timeline.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  factory BreathingBloc({required SessionProgram program}) {
    final timeline = program.resolve();
    if (timeline.cycles.isEmpty) {
      throw ArgumentError('Program "${program.name}" has no cycles.');
    }
    if (timeline.cycles.first.phases.isEmpty) {
      throw ArgumentError(
        'Program "${program.name}": first cycle has no phases.',
      );
    }
    final firstPhase = timeline.cycles.first.phases.first;
    return BreathingBloc._(
      program: program,
      timeline: timeline,
      initialState: BreathingState(
        selectedProgram: program,
        currentPhase: firstPhase.type,
        phaseSecondsRemaining: firstPhase.duration.inSeconds,
        sessionSecondsRemaining: timeline.totalSeconds,
        totalCycles: timeline.cycles.length,
        showTopCircle: _hasPhaseType(timeline, PhaseType.holdIn),
        showBottomCircle: _hasPhaseType(timeline, PhaseType.holdOut),
        extendedExhaleCycles: _extendedCycles(
          timeline,
          PhaseType.extendedExhale,
        ),
        extendedInhaleCycles: _extendedCycles(
          timeline,
          PhaseType.extendedInhale,
        ),
      ),
    );
  }

  BreathingBloc._({
    required SessionProgram program,
    required ResolvedTimeline timeline,
    required BreathingState initialState,
  }) : _program = program,
       _timeline = timeline,
       super(initialState) {
    on<PlayPressed>(_onPlayPressed);
    on<PausePressed>(_onPausePressed);
    on<ResetPressed>(_onResetPressed);
    on<ProgramSelected>(_onProgramSelected);
    on<PhaseCompleted>(_onPhaseCompleted);
    on<BreathingTickUpdated>(_onTickUpdated);
  }

  static bool _hasPhaseType(ResolvedTimeline timeline, PhaseType type) =>
      timeline.cycles.any((c) => c.phases.any((p) => p.type == type));

  static Set<int> _extendedCycles(ResolvedTimeline timeline, PhaseType type) {
    final result = <int>{};
    for (var i = 0; i < timeline.cycles.length; i++) {
      if (timeline.cycles[i].phases.any((p) => p.type == type)) {
        result.add(i + 1);
      }
    }
    return result;
  }

  SessionProgram _program;
  ResolvedTimeline _timeline;

  Ticker? _ticker;

  /// 0-based index of the current cycle in [_timeline].
  int _absCycle = 0;

  /// 0-based index of the current phase within [_timeline.cycles[_absCycle]].
  int _phaseIndex = 0;

  Duration _lastTickElapsed = Duration.zero;
  Duration _phaseAccumulated = Duration.zero;

  /// True while the current or upcoming inhale must start from the deep zone.
  /// Set when extendedExhale ends; cleared when inhale ends.
  bool _startFromDeep = false;

  /// True while the current or upcoming exhale must recover from the top zone.
  /// Set when extendedInhale ends; cleared when exhale ends.
  bool _startFromDeepTop = false;

  @override
  Future<void> close() {
    _ticker?.dispose();
    return super.close();
  }

  void _onPlayPressed(PlayPressed event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.idle &&
        state.status != SessionStatus.paused) {
      return;
    }

    if (state.status == SessionStatus.idle) {
      _absCycle = 0;
      _phaseIndex = 0;
      _phaseAccumulated = Duration.zero;
      _lastTickElapsed = Duration.zero;
      _startFromDeep = false;
      _startFromDeepTop = false;
      _ticker ??= Ticker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();

      emit(
        state.copyWith(
          status: SessionStatus.playing,
          currentPhase: _timeline.cycles.first.phases.first.type,
          phaseSecondsRemaining: _secondsRemaining(),
          nextPhaseType: _nextPhaseType,
          isNearPhaseEnd: false,
        ),
      );
    } else {
      _lastTickElapsed = Duration.zero;
      _ticker ??= Ticker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();
      emit(state.copyWith(status: SessionStatus.playing));
    }
  }

  void _onPausePressed(PausePressed event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.playing) return;
    _ticker?.stop();
    _lastTickElapsed = Duration.zero;
    emit(state.copyWith(status: SessionStatus.paused));
  }

  void _onResetPressed(ResetPressed event, Emitter<BreathingState> emit) {
    _ticker?.stop();
    _absCycle = 0;
    _phaseIndex = 0;
    _phaseAccumulated = Duration.zero;
    _lastTickElapsed = Duration.zero;
    _startFromDeep = false;
    _startFromDeepTop = false;
    final firstPhase = _timeline.cycles.first.phases.first;
    emit(
      BreathingState(
        selectedProgram: state.selectedProgram,
        currentPhase: firstPhase.type,
        phaseSecondsRemaining: firstPhase.duration.inSeconds,
        sessionSecondsRemaining: _timeline.totalSeconds,
        totalCycles: state.totalCycles,
        showTopCircle: state.showTopCircle,
        showBottomCircle: state.showBottomCircle,
        extendedExhaleCycles: state.extendedExhaleCycles,
        extendedInhaleCycles: state.extendedInhaleCycles,
      ),
    );
  }

  void _onProgramSelected(ProgramSelected event, Emitter<BreathingState> emit) {
    _ticker?.stop();
    _program = event.program;
    _timeline = _program.resolve();
    _absCycle = 0;
    _phaseIndex = 0;
    _phaseAccumulated = Duration.zero;
    _lastTickElapsed = Duration.zero;
    _startFromDeep = false;
    _startFromDeepTop = false;
    final firstPhase = _timeline.cycles.first.phases.first;
    emit(
      BreathingState(
        selectedProgram: event.program,
        currentPhase: firstPhase.type,
        phaseSecondsRemaining: firstPhase.duration.inSeconds,
        sessionSecondsRemaining: _timeline.totalSeconds,
        totalCycles: _timeline.cycles.length,
        showTopCircle: _hasPhaseType(_timeline, PhaseType.holdIn),
        showBottomCircle: _hasPhaseType(_timeline, PhaseType.holdOut),
        extendedExhaleCycles: _extendedCycles(
          _timeline,
          PhaseType.extendedExhale,
        ),
        extendedInhaleCycles: _extendedCycles(
          _timeline,
          PhaseType.extendedInhale,
        ),
      ),
    );
  }

  // Public event — for external triggering and tests.
  void _onPhaseCompleted(PhaseCompleted event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.playing) return;

    _updateStartFromDeep(state.currentPhase);
    _phaseAccumulated = Duration.zero;

    final currentCyclePhases = _timeline.cycles[_absCycle].phases;
    final nextPhaseIndex = _phaseIndex + 1;

    if (nextPhaseIndex < currentCyclePhases.length) {
      _phaseIndex = nextPhaseIndex;
      final next = currentCyclePhases[_phaseIndex];
      emit(
        state.copyWith(
          currentPhase: next.type,
          phaseSecondsRemaining: next.duration.inSeconds,
          sessionSecondsRemaining: _sessionSecondsRemaining(),
          fillLevel: _fillLevelForPhase(next.type, 0),
          deepZoneFill: _deepZoneFillForPhase(next.type, 0),
          topZoneFill: _topZoneFillForPhase(next.type, 0),
          circleScale: _circleScaleForPhase(next.type, 0),
          circleOpacity: _circleOpacityForPhase(next.type, 0),
          circleBottomScale: _circleBottomScaleForPhase(next.type, 0),
          circleBottomOpacity: _circleBottomOpacityForPhase(next.type, 0),
          nextPhaseType: _nextPhaseType,
          isNearPhaseEnd: false,
        ),
      );
    } else if (_absCycle + 1 < _timeline.cycles.length) {
      _absCycle++;
      _phaseIndex = 0;
      final next = _timeline.cycles[_absCycle].phases[0];
      emit(
        state.copyWith(
          currentPhase: next.type,
          currentCycle: _absCycle + 1,
          phaseSecondsRemaining: next.duration.inSeconds,
          sessionSecondsRemaining: _sessionSecondsRemaining(),
          fillLevel: _fillLevelForPhase(next.type, 0),
          deepZoneFill: _deepZoneFillForPhase(next.type, 0),
          topZoneFill: _topZoneFillForPhase(next.type, 0),
          circleScale: _circleScaleForPhase(next.type, 0),
          circleOpacity: _circleOpacityForPhase(next.type, 0),
          circleBottomScale: _circleBottomScaleForPhase(next.type, 0),
          circleBottomOpacity: _circleBottomOpacityForPhase(next.type, 0),
          nextPhaseType: _nextPhaseType,
          isNearPhaseEnd: false,
        ),
      );
    } else {
      _ticker?.stop();
      _startFromDeep = false;
      _startFromDeepTop = false;
      emit(
        state.copyWith(
          status: SessionStatus.completed,
          fillLevel: 0,
          deepZoneFill: 0,
          topZoneFill: 0,
          sessionSecondsRemaining: 0,
          nextPhaseType: () => null,
          isNearPhaseEnd: false,
        ),
      );
    }
  }

  // Ticker event — advances through as many phases as the delta spans so that
  // large deltas (e.g. after a background wakeup) never stall on short phases.
  void _onTickUpdated(
    BreathingTickUpdated event,
    Emitter<BreathingState> emit,
  ) {
    if (state.status != SessionStatus.playing) return;

    _phaseAccumulated += event.delta;

    // Carry overshoot across as many consecutive phase boundaries as needed.
    while (true) {
      final phase = _timeline.cycles[_absCycle].phases[_phaseIndex];
      if (_phaseAccumulated < phase.duration) break;

      _updateStartFromDeep(phase.type);
      // Carry overshoot so sub-phase timing drift doesn't compound.
      _phaseAccumulated -= phase.duration;

      final nextPhaseIndex = _phaseIndex + 1;
      if (nextPhaseIndex < _timeline.cycles[_absCycle].phases.length) {
        _phaseIndex = nextPhaseIndex;
      } else if (_absCycle + 1 < _timeline.cycles.length) {
        _absCycle++;
        _phaseIndex = 0;
      } else {
        _ticker?.stop();
        _startFromDeep = false;
        _startFromDeepTop = false;
        emit(
          state.copyWith(
            status: SessionStatus.completed,
            fillLevel: 0,
            deepZoneFill: 0,
            topZoneFill: 0,
            sessionSecondsRemaining: 0,
            nextPhaseType: () => null,
            isNearPhaseEnd: false,
          ),
        );
        return;
      }
    }

    final currentPhase = _timeline.cycles[_absCycle].phases[_phaseIndex];
    // Guard against zero-duration phases to avoid NaN from division by zero.
    final progress = currentPhase.duration.inMicroseconds > 0
        ? _phaseAccumulated.inMicroseconds /
              currentPhase.duration.inMicroseconds
        : 0.0;
    emit(
      state.copyWith(
        currentPhase: currentPhase.type,
        currentCycle: _absCycle + 1,
        phaseSecondsRemaining: _secondsRemaining(),
        sessionSecondsRemaining: _sessionSecondsRemaining(),
        fillLevel: _fillLevelForPhase(currentPhase.type, progress),
        deepZoneFill: _deepZoneFillForPhase(currentPhase.type, progress),
        topZoneFill: _topZoneFillForPhase(currentPhase.type, progress),
        circleScale: _circleScaleForPhase(currentPhase.type, progress),
        circleOpacity: _circleOpacityForPhase(currentPhase.type, progress),
        circleBottomScale: _circleBottomScaleForPhase(
          currentPhase.type,
          progress,
        ),
        circleBottomOpacity: _circleBottomOpacityForPhase(
          currentPhase.type,
          progress,
        ),
        nextPhaseType: _nextPhaseType,
        isNearPhaseEnd: _isNearPhaseEnd(),
      ),
    );
  }

  void _onTick(Duration elapsed) {
    if (isClosed) return;
    final delta = elapsed - _lastTickElapsed;
    _lastTickElapsed = elapsed;
    add(BreathingTickUpdated(delta));
  }

  /// Called when [endingPhase] completes. Updates deep-zone tracking flags.
  void _updateStartFromDeep(PhaseType endingPhase) {
    if (endingPhase == PhaseType.extendedExhale) {
      _startFromDeep = true;
    } else if (endingPhase == PhaseType.inhale) {
      _startFromDeep = false;
    }
    if (endingPhase == PhaseType.extendedInhale) {
      _startFromDeepTop = true;
    } else if (endingPhase == PhaseType.exhale) {
      _startFromDeepTop = false;
    }
  }

  PhaseType? _nextPhaseType() {
    final currentCyclePhases = _timeline.cycles[_absCycle].phases;
    if (_phaseIndex + 1 < currentCyclePhases.length) {
      return currentCyclePhases[_phaseIndex + 1].type;
    } else if (_absCycle + 1 < _timeline.cycles.length) {
      return _timeline.cycles[_absCycle + 1].phases.first.type;
    }
    return null;
  }

  bool _isNearPhaseEnd() {
    final phase = _timeline.cycles[_absCycle].phases[_phaseIndex];
    final remaining = phase.duration - _phaseAccumulated;
    return remaining.inMilliseconds <= 500;
  }

  int _secondsRemaining() {
    final duration = _timeline.cycles[_absCycle].phases[_phaseIndex].duration;
    final remaining = duration - _phaseAccumulated;
    return (remaining.inMilliseconds / 1000).ceil().clamp(
      0,
      (duration.inMilliseconds / 1000).ceil(),
    );
  }

  int _sessionSecondsRemaining() {
    var total = _secondsRemaining();
    final currentCyclePhases = _timeline.cycles[_absCycle].phases;
    for (var i = _phaseIndex + 1; i < currentCyclePhases.length; i++) {
      total += (currentCyclePhases[i].duration.inMilliseconds / 1000).ceil();
    }
    for (var c = _absCycle + 1; c < _timeline.cycles.length; c++) {
      for (final phase in _timeline.cycles[c].phases) {
        total += (phase.duration.inMilliseconds / 1000).ceil();
      }
    }
    return total;
  }

  // Spatial threshold: fraction of progress at which the middle zone is fully
  // empty during extendedExhale (middle flex=6, lower flex=2 → 6/8 = 0.75).
  static const double _kExtendedExhaleThreshold = 6.0 / (6.0 + 2.0); // 0.75
  static const double _kDeepInhaleThreshold =
      1.0 - _kExtendedExhaleThreshold; // 0.25

  double _fillLevelForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.inhale =>
        _startFromDeep ? _deepInhaleFillLevel(progress) : progress,
      PhaseType.extendedInhale => (progress / _kExtendedExhaleThreshold).clamp(
        0.0,
        1.0,
      ),
      PhaseType.holdIn => 1.0,
      PhaseType.exhale =>
        _startFromDeepTop ? _deepTopExhaleFillLevel(progress) : 1.0 - progress,
      PhaseType.extendedExhale =>
        (1.0 - progress / _kExtendedExhaleThreshold).clamp(0.0, 1.0),
      PhaseType.holdOut => 0.0,
    };
  }

  /// fillLevel for inhale that starts at the deep-zone bottom.
  /// Progress 0→0.25: lower zone clears (fillLevel stays 0).
  /// Progress 0.25→1.0: middle zone fills at uniform speed.
  double _deepInhaleFillLevel(double progress) {
    if (progress <= _kDeepInhaleThreshold) return 0;
    return ((progress - _kDeepInhaleThreshold) / _kExtendedExhaleThreshold)
        .clamp(0.0, 1.0);
  }

  /// fillLevel for exhale that recovers from a full top zone.
  /// Progress 0→0.25: top zone clears (fillLevel stays 1.0).
  /// Progress 0.25→1.0: middle zone empties at uniform speed.
  double _deepTopExhaleFillLevel(double progress) {
    if (progress <= _kDeepInhaleThreshold) return 1;
    return (1.0 -
            (progress - _kDeepInhaleThreshold) / _kExtendedExhaleThreshold)
        .clamp(0.0, 1.0);
  }

  double _deepZoneFillForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.extendedExhale when progress > _kExtendedExhaleThreshold =>
        ((progress - _kExtendedExhaleThreshold) /
                (1.0 - _kExtendedExhaleThreshold))
            .clamp(0.0, 1.0),
      PhaseType.holdOut when _startFromDeep => 1.0,
      PhaseType.inhale when _startFromDeep =>
        (1.0 - progress / _kDeepInhaleThreshold).clamp(0.0, 1.0),
      _ => 0.0,
    };
  }

  double _topZoneFillForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.extendedInhale when progress > _kExtendedExhaleThreshold =>
        ((progress - _kExtendedExhaleThreshold) /
                (1.0 - _kExtendedExhaleThreshold))
            .clamp(0.0, 1.0),
      PhaseType.holdIn when _startFromDeepTop => 1.0,
      PhaseType.exhale when _startFromDeepTop =>
        (1.0 - progress / _kDeepInhaleThreshold).clamp(0.0, 1.0),
      _ => 0.0,
    };
  }

  double _circleScaleForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.holdIn => 1.0 - progress,
      _ => 1.0,
    };
  }

  double _circleOpacityForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.exhale when _startFromDeepTop =>
        (progress / _kDeepInhaleThreshold).clamp(0.0, 1.0),
      PhaseType.exhale => progress,
      PhaseType.extendedExhale => (progress / _kExtendedExhaleThreshold).clamp(
        0.0,
        1.0,
      ),
      PhaseType.extendedInhale =>
        1.0 -
            ((progress - _kExtendedExhaleThreshold) /
                    (1.0 - _kExtendedExhaleThreshold))
                .clamp(0.0, 1.0),
      PhaseType.holdIn when _startFromDeepTop => 0.0,
      _ => 1.0,
    };
  }

  double _circleBottomScaleForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.holdOut => 1.0 - progress,
      _ => 1.0,
    };
  }

  double _circleBottomOpacityForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.inhale => progress,
      PhaseType.extendedInhale => (progress / _kExtendedExhaleThreshold).clamp(
        0.0,
        1.0,
      ),
      PhaseType.extendedExhale =>
        1.0 -
            ((progress - _kExtendedExhaleThreshold) /
                    (1.0 - _kExtendedExhaleThreshold))
                .clamp(0.0, 1.0),
      _ => 1.0,
    };
  }
}
