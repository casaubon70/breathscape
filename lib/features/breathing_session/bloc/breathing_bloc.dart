import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  BreathingBloc({required this.pattern}) : super(const BreathingState()) {
    on<PlayPressed>(_onPlayPressed);
    on<PausePressed>(_onPausePressed);
    on<ResetPressed>(_onResetPressed);
    on<PhaseCompleted>(_onPhaseCompleted);
    on<BreathingTickUpdated>(_onTickUpdated);
  }

  final BreathingPattern pattern;

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
        currentPhase: pattern.phases[_phaseIndex].type,
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
    emit(const BreathingState());
  }

  // Öffentliches Event – für externe Auslösung und Scheibe-2-Tests.
  void _onPhaseCompleted(PhaseCompleted event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.playing) return;
    final nextPhase = _nextPhaseType();
    emit(
      state.copyWith(
        currentPhase: nextPhase,
        currentCycle: _nextCycle(),
        fillLevel: _fillLevelForPhase(nextPhase, 0),
        circleScale: _circleScaleForPhase(nextPhase, 0),
        circleOpacity: _circleOpacityForPhase(nextPhase, 0),
        circleBottomScale: _circleBottomScaleForPhase(nextPhase, 0),
        circleBottomOpacity: _circleBottomOpacityForPhase(nextPhase, 0),
      ),
    );
    _phaseIndex = (_phaseIndex + 1) % pattern.phases.length;
  }

  // Ticker-Event – verarbeitet delta und wechselt Phase direkt (kein add()).
  void _onTickUpdated(
    BreathingTickUpdated event,
    Emitter<BreathingState> emit,
  ) {
    if (state.status != SessionStatus.playing) return;

    _phaseAccumulated += event.delta;
    final phaseDuration = pattern.phases[_phaseIndex].duration;

    if (_phaseAccumulated >= phaseDuration) {
      _phaseAccumulated = Duration.zero;
      _phaseIndex = (_phaseIndex + 1) % pattern.phases.length;
      final nextPhase = pattern.phases[_phaseIndex].type;
      final nextCycle = nextPhase == PhaseType.inhale
          ? state.currentCycle + 1
          : state.currentCycle;
      emit(
        state.copyWith(
          currentPhase: nextPhase,
          currentCycle: nextCycle,
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

  PhaseType _nextPhaseType() {
    final nextIndex = (_phaseIndex + 1) % pattern.phases.length;
    return pattern.phases[nextIndex].type;
  }

  int _nextCycle() {
    final nextPhase = _nextPhaseType();
    return nextPhase == PhaseType.inhale
        ? state.currentCycle + 1
        : state.currentCycle;
  }

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
