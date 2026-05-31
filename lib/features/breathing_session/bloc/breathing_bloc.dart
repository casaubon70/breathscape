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

  /// Returns the effective phase for [phaseIndex] at [cycle].
  /// Substitutes exhale → extendedExhale and inhale → extendedInhale on every
  /// Nth cycle according to the pattern intervals.
  BreathingPhase _effectivePhase(int phaseIndex, int cycle) {
    final phase = _pattern.phases[phaseIndex];
    final exhaleInterval = _pattern.extendedExhaleInterval;
    if (phase.type == PhaseType.exhale &&
        exhaleInterval != null &&
        exhaleInterval > 0 &&
        cycle > 0 &&
        cycle % exhaleInterval == 0) {
      return BreathingPhase(
        type: PhaseType.extendedExhale,
        duration: phase.duration + const Duration(seconds: 2),
      );
    }
    final inhaleInterval = _pattern.extendedInhaleInterval;
    if (phase.type == PhaseType.inhale &&
        inhaleInterval != null &&
        inhaleInterval > 0 &&
        cycle > 0 &&
        cycle % inhaleInterval == 0) {
      return BreathingPhase(
        type: PhaseType.extendedInhale,
        duration: phase.duration + const Duration(seconds: 2),
      );
    }
    return phase;
  }

  /// Called when [endingPhase] completes. Updates [_startFromDeep] and
  /// [_startFromDeepTop]:
  /// - extendedExhale ending  → next inhale must start from deep zone
  /// - inhale ending          → deep-zone inhale is done, reset flag
  /// - extendedInhale ending  → next exhale must recover from top zone
  /// - exhale ending          → top-zone recovery exhale is done, reset flag
  /// - all other phases       → flags unchanged
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

  void _onPlayPressed(PlayPressed event, Emitter<BreathingState> emit) {
    if (state.status != SessionStatus.idle &&
        state.status != SessionStatus.paused) {
      return;
    }

    if (state.status == SessionStatus.idle) {
      _phaseIndex = 0;
      _phaseAccumulated = Duration.zero;
      _lastTickElapsed = Duration.zero;
      // Fix: reset alongside all other session-start fields so previous
      // _startFromDeep/_startFromDeepTop can never bleed into a fresh session.
      _startFromDeep = false;
      _startFromDeepTop = false;
      _ticker ??= Ticker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();

      emit(
        state.copyWith(
          status: SessionStatus.playing,
          // Fix: use the actual first phase type, not a hardcoded inhale.
          currentPhase: _effectivePhase(_phaseIndex, state.currentCycle).type,
          phaseSecondsRemaining: _secondsRemaining(state.currentCycle),
        ),
      );
    } else {
      // Resuming from pause — retain phase, fillLevel, deepZoneFill as-is.
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
    _phaseIndex = 0;
    _phaseAccumulated = Duration.zero;
    _lastTickElapsed = Duration.zero;
    _startFromDeep = false;
    _startFromDeepTop = false;
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
    _startFromDeep = false;
    _startFromDeepTop = false;
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

    _updateStartFromDeep(state.currentPhase);

    final nextIndex = (_phaseIndex + 1) % _pattern.phases.length;
    final nextBaseType = _pattern.phases[nextIndex].type;
    if (nextBaseType == PhaseType.inhale &&
        state.currentCycle >= _pattern.defaultCycles) {
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
        ),
      );
      return;
    }
    _phaseIndex = nextIndex;
    final nextCycle = nextBaseType == PhaseType.inhale
        ? state.currentCycle + 1
        : state.currentCycle;
    final effective = _effectivePhase(_phaseIndex, nextCycle);
    final nextPhase = effective.type;
    emit(
      state.copyWith(
        currentPhase: nextPhase,
        currentCycle: nextCycle,
        deepZoneFill: _deepZoneFillForPhase(nextPhase, 0),
        topZoneFill: _topZoneFillForPhase(nextPhase, 0),
        phaseSecondsRemaining: effective.duration.inSeconds,
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
    final effectiveDuration = _effectivePhase(
      _phaseIndex,
      state.currentCycle,
    ).duration;

    if (_phaseAccumulated >= effectiveDuration) {
      _updateStartFromDeep(state.currentPhase);

      // Fix: carry the overshoot forward instead of resetting to zero,
      // so sub-phase timing drift doesn't compound over a session.
      _phaseAccumulated -= effectiveDuration;

      final nextIndex = (_phaseIndex + 1) % _pattern.phases.length;
      final nextBaseType = _pattern.phases[nextIndex].type;
      if (nextBaseType == PhaseType.inhale &&
          state.currentCycle >= _pattern.defaultCycles) {
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
          ),
        );
        return;
      }
      _phaseIndex = nextIndex;
      final nextCycle = nextBaseType == PhaseType.inhale
          ? state.currentCycle + 1
          : state.currentCycle;
      final effective = _effectivePhase(_phaseIndex, nextCycle);
      final nextPhase = effective.type;
      emit(
        state.copyWith(
          currentPhase: nextPhase,
          currentCycle: nextCycle,
          deepZoneFill: _deepZoneFillForPhase(nextPhase, 0),
          topZoneFill: _topZoneFillForPhase(nextPhase, 0),
          phaseSecondsRemaining: _secondsRemaining(nextCycle),
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
          _phaseAccumulated.inMicroseconds / effectiveDuration.inMicroseconds;
      emit(
        state.copyWith(
          phaseSecondsRemaining: _secondsRemaining(state.currentCycle),
          sessionSecondsRemaining: _sessionSecondsRemaining(state.currentCycle),
          fillLevel: _fillLevelForPhase(state.currentPhase, progress),
          deepZoneFill: _deepZoneFillForPhase(state.currentPhase, progress),
          topZoneFill: _topZoneFillForPhase(state.currentPhase, progress),
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

  int _secondsRemaining(int cycle) {
    final duration = _effectivePhase(_phaseIndex, cycle).duration;
    final remaining = duration - _phaseAccumulated;
    return (remaining.inMilliseconds / 1000).ceil().clamp(
      0,
      duration.inSeconds,
    );
  }

  /// Seconds remaining in the full session from the current position.
  /// Accounts for extended-exhale +2 s on each qualifying cycle.
  int _sessionSecondsRemaining(int currentCycle) {
    var total = _secondsRemaining(currentCycle);
    // Remaining phases in current cycle using effective durations.
    for (var i = _phaseIndex + 1; i < _pattern.phases.length; i++) {
      total += _effectivePhase(i, currentCycle).duration.inSeconds;
    }
    // All future complete cycles using effective durations.
    for (var c = currentCycle + 1; c <= _pattern.defaultCycles; c++) {
      for (var i = 0; i < _pattern.phases.length; i++) {
        total += _effectivePhase(i, c).duration.inSeconds;
      }
    }
    return total;
  }

  int _totalSessionSeconds() => _calcTotalSessionSeconds(_pattern);

  /// Computes the full session duration including extended-exhale/-inhale
  /// cycles.
  static int _calcTotalSessionSeconds(BreathingPattern pattern) {
    final exhaleInterval = pattern.extendedExhaleInterval;
    final inhaleInterval = pattern.extendedInhaleInterval;
    var total = 0;
    for (var c = 1; c <= pattern.defaultCycles; c++) {
      for (final phase in pattern.phases) {
        final isExtExhale =
            phase.type == PhaseType.exhale &&
            exhaleInterval != null &&
            exhaleInterval > 0 &&
            c % exhaleInterval == 0;
        final isExtInhale =
            phase.type == PhaseType.inhale &&
            inhaleInterval != null &&
            inhaleInterval > 0 &&
            c % inhaleInterval == 0;
        total +=
            phase.duration.inSeconds + ((isExtExhale || isExtInhale) ? 2 : 0);
      }
    }
    return total;
  }

  // Spatial threshold: fraction of progress at which the middle zone is fully
  // empty during extendedExhale (middle flex=6, lower flex=2 → 6/8 = 0.75).
  // The same ratio governs the reverse animation (inhale from deep zone).
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
      // Exhale extension: lower zone fills from top (0→1).
      PhaseType.extendedExhale when progress > _kExtendedExhaleThreshold =>
        ((progress - _kExtendedExhaleThreshold) /
                (1.0 - _kExtendedExhaleThreshold))
            .clamp(0.0, 1.0),
      // Hold after deep exhale: lower zone stays fully filled.
      PhaseType.holdOut when _startFromDeep => 1.0,
      // Deep inhale: lower zone drains upward (1→0) then middle fills.
      PhaseType.inhale when _startFromDeep =>
        (1.0 - progress / _kDeepInhaleThreshold).clamp(0.0, 1.0),
      _ => 0.0,
    };
  }

  double _topZoneFillForPhase(PhaseType phase, double progress) {
    return switch (phase) {
      // Inhale extension: upper zone fills from bottom (0→1).
      PhaseType.extendedInhale when progress > _kExtendedExhaleThreshold =>
        ((progress - _kExtendedExhaleThreshold) /
                (1.0 - _kExtendedExhaleThreshold))
            .clamp(0.0, 1.0),
      // Hold after deep inhale: upper zone stays fully filled.
      PhaseType.holdIn when _startFromDeepTop => 1.0,
      // Recovery exhale: upper zone drains downward (1→0) then middle empties.
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
      // Recovery exhale: top circle reappears quickly as top zone clears.
      PhaseType.exhale when _startFromDeepTop =>
        (progress / _kDeepInhaleThreshold).clamp(0.0, 1.0),
      PhaseType.exhale => progress,
      // Fade in over the middle-zone portion at the same apparent speed.
      PhaseType.extendedExhale => (progress / _kExtendedExhaleThreshold).clamp(
        0.0,
        1.0,
      ),
      // Top circle fades out as the upper zone fills during deep inhale.
      PhaseType.extendedInhale =>
        1.0 -
            ((progress - _kExtendedExhaleThreshold) /
                    (1.0 - _kExtendedExhaleThreshold))
                .clamp(0.0, 1.0),
      // Top zone still filled during hold: keep circle hidden.
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
      // Bottom circle appears as middle fills during deep inhale.
      PhaseType.extendedInhale => (progress / _kExtendedExhaleThreshold).clamp(
        0.0,
        1.0,
      ),
      // Fade bottom circle out as deep zone fills (0.75→1).
      // Before 0.75 residual air in lower zone keeps circle visible.
      PhaseType.extendedExhale =>
        1.0 -
            ((progress - _kExtendedExhaleThreshold) /
                    (1.0 - _kExtendedExhaleThreshold))
                .clamp(0.0, 1.0),
      _ => 1.0,
    };
  }
}
