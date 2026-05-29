import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus { idle, playing, paused, completed }

final class BreathingState extends Equatable {
  const BreathingState({
    required this.selectedPattern,
    this.status = SessionStatus.idle,
    this.currentPhase = PhaseType.inhale,
    this.fillLevel = 0.0,
    this.currentCycle = 1,
    this.phaseSecondsRemaining = 0,
    this.sessionSecondsRemaining = 0,
    this.circleScale = 1.0,
    this.circleOpacity = 1.0,
    this.circleBottomScale = 1.0,
    this.circleBottomOpacity = 0.0,
    this.deepZoneFill = 0.0,
  });

  final BreathingPattern selectedPattern;
  final SessionStatus status;
  final PhaseType currentPhase;
  final double fillLevel;
  final int currentCycle;
  final int phaseSecondsRemaining;
  final int sessionSecondsRemaining;
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;

  /// Derived: true whenever [currentPhase] is [PhaseType.extendedExhale].
  bool get isExtendedExhale => currentPhase == PhaseType.extendedExhale;

  /// How much of the lower surfaceDim zone has been filled (0.0–1.0).
  /// Only > 0 during the extension phase of an extended exhale.
  final double deepZoneFill;

  BreathingState copyWith({
    BreathingPattern? selectedPattern,
    SessionStatus? status,
    PhaseType? currentPhase,
    double? fillLevel,
    int? currentCycle,
    int? phaseSecondsRemaining,
    int? sessionSecondsRemaining,
    double? circleScale,
    double? circleOpacity,
    double? circleBottomScale,
    double? circleBottomOpacity,
    double? deepZoneFill,
  }) {
    return BreathingState(
      selectedPattern: selectedPattern ?? this.selectedPattern,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      fillLevel: fillLevel ?? this.fillLevel,
      currentCycle: currentCycle ?? this.currentCycle,
      phaseSecondsRemaining:
          phaseSecondsRemaining ?? this.phaseSecondsRemaining,
      sessionSecondsRemaining:
          sessionSecondsRemaining ?? this.sessionSecondsRemaining,
      circleScale: circleScale ?? this.circleScale,
      circleOpacity: circleOpacity ?? this.circleOpacity,
      circleBottomScale: circleBottomScale ?? this.circleBottomScale,
      circleBottomOpacity: circleBottomOpacity ?? this.circleBottomOpacity,
      deepZoneFill: deepZoneFill ?? this.deepZoneFill,
    );
  }

  @override
  List<Object> get props => [
    selectedPattern,
    status,
    currentPhase,
    fillLevel,
    currentCycle,
    phaseSecondsRemaining,
    sessionSecondsRemaining,
    circleScale,
    circleOpacity,
    circleBottomScale,
    circleBottomOpacity,
    deepZoneFill,
  ];
}
