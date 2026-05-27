import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus { idle, playing, paused }

final class BreathingState extends Equatable {
  const BreathingState({
    this.status = SessionStatus.idle,
    this.currentPhase = PhaseType.inhale,
    this.fillLevel = 0.0,
    this.currentCycle = 1,
    this.circleScale = 1.0,
    this.circleOpacity = 1.0,
    this.circleBottomScale = 1.0,
    this.circleBottomOpacity = 0.0,
  });

  final SessionStatus status;
  final PhaseType currentPhase;
  final double fillLevel;
  final int currentCycle;
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;

  BreathingState copyWith({
    SessionStatus? status,
    PhaseType? currentPhase,
    double? fillLevel,
    int? currentCycle,
    double? circleScale,
    double? circleOpacity,
    double? circleBottomScale,
    double? circleBottomOpacity,
  }) {
    return BreathingState(
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      fillLevel: fillLevel ?? this.fillLevel,
      currentCycle: currentCycle ?? this.currentCycle,
      circleScale: circleScale ?? this.circleScale,
      circleOpacity: circleOpacity ?? this.circleOpacity,
      circleBottomScale: circleBottomScale ?? this.circleBottomScale,
      circleBottomOpacity: circleBottomOpacity ?? this.circleBottomOpacity,
    );
  }

  @override
  List<Object> get props => [
    status,
    currentPhase,
    fillLevel,
    currentCycle,
    circleScale,
    circleOpacity,
    circleBottomScale,
    circleBottomOpacity,
  ];
}
