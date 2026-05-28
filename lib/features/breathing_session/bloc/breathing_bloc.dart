import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  BreathingBloc({required BreathingPattern pattern})
    : _pattern = pattern,
      super(
        BreathingState(
          selectedPattern: pattern,
          phaseSecondsRemaining: pattern.phases.first.duration.inSeconds,
          sessionSecondsRemaining: _calcTotalSessionSeconds(pattern),
        ),
      ) {
    on<PlayPressed>(_onPlayPressed);
    on<PausePressed>(_onPausePressed);
    on<ResetPressed>(_onResetPressed);
    on<PatternSelected>(_onPatternSelected);
    on<PhaseCompleted>(_onPhaseCompleted);
    on<BreathingTickUpdated>(_onTickUpdated);
  }

  BreathingPattern _pattern;

  Ticker? _ticker;
  int _phaseIndex = 0;
  Duration _lastTickElapsed = Duration.zero;
  Duration _phaseAccumulated = Duration.zero;

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
      _phaseIndex = 0;
      _phaseAccumulated = Duration.zero;
    }

    _lastTickElapsed = Duration.zero;
    _ticker ??= Ticker(_onTick);
    if (!_ticker!.isActive) {
      _ticker!.start();
    }

    emit(
      state.copyWith(
        status: SessionStatus.playing,
        currentPhase: _pattern.phases[_phaseIndex].type,
        phaseSecondsRemaining: _secondsRemaining(),
      ),
    );
  }

  void _onPausePressed(PausePressed event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.playing) return;
    _ticker?.stop();
    _lastTickElapsed = Duration.zero;
    emit(state.copyWith(status: SessionStatus.paused));
  }

  void _onResetPressed(ResetPressed event, Emitter<BreathingState> emit) {
    _ticker?.stop();
    _phaseIndex = 0;
    _phaseAccumulated = Duration.zero;
    _lastTickElapsed = Duration.zero;
    emit(
      BreathingState(
        selectedPattern: _pattern,
        phaseSecondsRemaining: _pattern.phases.first.duration.inSeconds,
        sessionSecondsRemaining: _totalSessionSeconds(),
      ),
    );
  }

  void _onPatternSelected(PatternSelected event, Emitter<BreathingState> emit) {
    _ticker?.stop();
    _pattern = event.pattern;
    _phaseIndex = 0;
    _phaseAccumulated = Duration.zero;
    _lastTickElapsed = Duration.zero;
    emit(
      BreathingState(
        selectedPattern: _pattern,
        phaseSecondsRemaining: _pattern.phases.first.duration.inSeconds,
        sessionSecondsRemaining: _totalSessionSeconds(),
      ),
    );
  }

  // Öffentliches Event – für externe Auslösung und Scheibe-2-Tests.
  void _onPhaseCompleted(PhaseCompleted event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.playing) return;
    final nextIndex = (_phaseIndex + 1) % _pattern.phases.length;
    final nextPhase = _pattern.phases[nextIndex].type;
    if (nextPhase == PhaseType.inhale &&
        state.currentCycle >= _pattern.defaultCycles) {
      _ticker?.stop();
      emit(
        state.copyWith(
          status: SessionStatus.completed,
          fillLevel: 0,
          sessionSecondsRemaining: 0,
        ),
      );
      return;
    }
    // Update _phaseIndex before helpers so _sessionSecondsRemaining is correct.
    _phaseIndex = nextIndex;
    final nextCycle = nextPhase == PhaseType.inhale
        ? state.currentCycle + 1
        : state.currentCycle;
    emit(
      state.copyWith(
        currentPhase: nextPhase,
        currentCycle: nextCycle,
        phaseSecondsRemaining: _pattern.phases[_phaseIndex].duration.inSeconds,
        sessionSecondsRemaining: _sessionSecondsRemaining(nextCycle),
        fillLevel: _fillLevelForPhase(nextPhase, 0),
        circleScale: _circleScaleForPhase(nextPhase, 0),
        circleOpacity: _circleOpacityForPhase(nextPhase, 0),
        circleBottomScale: _circleBottomScaleForPhase(nextPhase, 0),
        circleBottomOpacity: _circleBottomOpacityForPhase(nextPhase, 0),
      ),
    );
  }

  // Ticker-Event – verarbeitet delta und wechselt Phase direkt (kein add()).
  void _onTickUpdated(
    BreathingTickUpdated event,
    Emitter<BreathingState> emit,
  ) {
    if (state.status != SessionStatus.playing) return;

    _phaseAccumulated += event.delta;
    final phaseDuration = _pattern.phases[_phaseIndex].duration;

    if (_phaseAccumulated >= phaseDuration) {
      _phaseAccumulated = Duration.zero;
      final nextIndex = (_phaseIndex + 1) % _pattern.phases.length;
      final nextPhase = _pattern.phases[nextIndex].type;
      if (nextPhase == PhaseType.inhale &&
          state.currentCycle >= _pattern.defaultCycles) {
        _ticker?.stop();
        emit(
          state.copyWith(
            status: SessionStatus.completed,
            fillLevel: 0,
            sessionSecondsRemaining: 0,
          ),
        );
        return;
      }
      _phaseIndex = nextIndex;
      final nextCycle = nextPhase == PhaseType.inhale
          ? state.currentCycle + 1
          : state.currentCycle;
      emit(
        state.copyWith(
          currentPhase: nextPhase,
          currentCycle: nextCycle,
          phaseSecondsRemaining: _secondsRemaining(),
          sessionSecondsRemaining: _sessionSecondsRemaining(nextCycle),
          fillLevel: _fillLevelForPhase(nextPhase, 0),
          circleScale: _circleScaleForPhase(nextPhase, 0),
          circleOpacity: _circleOpacityForPhase(nextPhase, 0),
          circleBottomScale: _circleBottomScaleForPhase(nextPhase, 0),
          circleBottomOpacity: _circleBottomOpacityForPhase(nextPhase, 0),
        ),
      );
    } else {
      final progress =
          _phaseAccumulated.inMicroseconds / phaseDuration.inMicroseconds;
      emit(
        state.copyWith(
          phaseSecondsRemaining: _secondsRemaining(),
          sessionSecondsRemaining: _sessionSecondsRemaining(state.currentCycle),
          fillLevel: _fillLevelForPhase(state.currentPhase, progress),
          circleScale: _circleScaleForPhase(state.currentPhase, progress),
          circleOpacity: _circleOpacityForPhase(state.currentPhase, progress),
          circleBottomScale: _circleBottomScaleForPhase(
            state.currentPhase,
            progress,
          ),
          circleBottomOpacity: _circleBottomOpacityForPhase(
            state.currentPhase,
            progress,
          ),
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (isClosed) return;
    final delta = elapsed - _lastTickElapsed;
    _lastTickElapsed = elapsed;
    add(BreathingTickUpdated(delta));
  }

  int _secondsRemaining() {
    final duration = _pattern.phases[_phaseIndex].duration;
    final remaining = duration - _phaseAccumulated;
    return (remaining.inMilliseconds / 1000).ceil().clamp(
      0,
      duration.inSeconds,
    );
  }

  /// Seconds remaining in the full session from the current tick position.
  int _sessionSecondsRemaining(int currentCycle) {
    final cycleSeconds = _pattern.phases
        .fold(0, (int s, p) => s + p.duration.inSeconds);
    var remainingInCycle = 0;
    for (var i = _phaseIndex + 1; i < _pattern.phases.length; i++) {
      remainingInCycle += _pattern.phases[i].duration.inSeconds;
    }
    final completeCyclesLeft = _pattern.defaultCycles - currentCycle;
    return _secondsRemaining() +
        remainingInCycle +
        completeCyclesLeft * cycleSeconds;
  }

  int _totalSessionSeconds() =>
      _calcTotalSessionSeconds(_pattern);

  static int _calcTotalSessionSeconds(BreathingPattern pattern) =>
      pattern.defaultCycles *
      pattern.phases.fold(0, (int s, p) => s + p.duration.inSeconds);

  double _fillLevelForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      PhaseType.inhale => progress,
      PhaseType.holdIn => 1.0,
      PhaseType.exhale => 1.0 - progress,
      PhaseType.holdOut => 0.0,
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
      PhaseType.exhale => progress,
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
      _ => 1.0,
    };
  }
}
