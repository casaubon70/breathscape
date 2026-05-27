import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus { idle, playing, paused }

final class BreathingState extends Equatable {
  const BreathingState({
    required this.selectedPattern,
    this.status = SessionStatus.idle,
    this.currentPhase = PhaseType.inhale,
    this.fillLevel = 0.0,
    this.currentCycle = 1,
    this.phaseSecondsRemaining = 0,
    this.circleScale = 1.0,
    this.circleOpacity = 1.0,
    this.circleBottomScale = 1.0,
    this.circleBottomOpacity = 0.0,
  });

  final BreathingPattern selectedPattern;
  final SessionStatus status;
  final PhaseType currentPhase;
  final double fillLevel;
  final int currentCycle;
  final int phaseSecondsRemaining;
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;

  BreathingState copyWith({
    BreathingPattern? selectedPattern,
    SessionStatus? status,
    PhaseType? currentPhase,
    double? fillLevel,
    int? currentCycle,
    int? phaseSecondsRemaining,
    double? circleScale,
    double? circleOpacity,
    double? circleBottomScale,
    double? circleBottomOpacity,
  }) {
    return BreathingState(
      selectedPattern: selectedPattern ?? this.selectedPattern,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      fillLevel: fillLevel ?? this.fillLevel,
      currentCycle: currentCycle ?? this.currentCycle,
      phaseSecondsRemaining:
          phaseSecondsRemaining ?? this.phaseSecondsRemaining,
      circleScale: circleScale ?? this.circleScale,
      circleOpacity: circleOpacity ?? this.circleOpacity,
      circleBottomScale: circleBottomScale ?? this.circleBottomScale,
      circleBottomOpacity: circleBottomOpacity ?? this.circleBottomOpacity,
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
    circleScale,
    circleOpacity,
    circleBottomScale,
    circleBottomOpacity,
  ];
}
