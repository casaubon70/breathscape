import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus { idle, playing, paused, completed }

final class BreathingState extends Equatable {
  const BreathingState({
    required this.selectedProgram,
    this.status = SessionStatus.idle,
    this.currentPhase = PhaseType.inhale,
    this.fillLevel = 0.0,
    this.currentCycle = 1,
    this.totalCycles = 10,
    this.phaseSecondsRemaining = 0,
    this.sessionSecondsRemaining = 0,
    this.showTopCircle = false,
    this.showBottomCircle = false,
    this.extendedExhaleCycles = const <int>{},
    this.extendedInhaleCycles = const <int>{},
    this.circleScale = 1.0,
    this.circleOpacity = 1.0,
    this.circleBottomScale = 1.0,
    this.circleBottomOpacity = 0.0,
    this.deepZoneFill = 0.0,
    this.topZoneFill = 0.0,
    this.nextPhaseType,
    this.isNearPhaseEnd = false,
  });

  final SessionProgram selectedProgram;
  final SessionStatus status;
  final PhaseType currentPhase;
  final double fillLevel;
  final int currentCycle;

  /// Total number of cycles in the session (resolved from the program).
  final int totalCycles;

  final int phaseSecondsRemaining;
  final int sessionSecondsRemaining;

  /// Whether the breathing animation should render the top hold circle.
  final bool showTopCircle;

  /// Whether the breathing animation should render the bottom hold circle.
  final bool showBottomCircle;

  /// 1-based cycle indices that contain an extendedExhale phase.
  final Set<int> extendedExhaleCycles;

  /// 1-based cycle indices that contain an extendedInhale phase.
  final Set<int> extendedInhaleCycles;

  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;

  /// Derived: true whenever [currentPhase] is [PhaseType.extendedExhale].
  bool get isExtendedExhale => currentPhase == PhaseType.extendedExhale;

  /// Derived: true whenever [currentPhase] is [PhaseType.extendedInhale].
  bool get isExtendedInhale => currentPhase == PhaseType.extendedInhale;

  /// How much of the lower surfaceDim zone has been filled (0.0–1.0).
  final double deepZoneFill;

  /// How much of the upper surfaceDim zone has been filled (0.0–1.0).
  final double topZoneFill;

  /// The phase type that follows [currentPhase]; null when [currentPhase] is
  /// the last phase of the session.
  final PhaseType? nextPhaseType;

  /// True during the last 500 ms of the current phase, signalling that the
  /// noise crossfade to [nextPhaseType] should begin.
  final bool isNearPhaseEnd;

  BreathingState copyWith({
    SessionProgram? selectedProgram,
    SessionStatus? status,
    PhaseType? currentPhase,
    double? fillLevel,
    int? currentCycle,
    int? totalCycles,
    int? phaseSecondsRemaining,
    int? sessionSecondsRemaining,
    bool? showTopCircle,
    bool? showBottomCircle,
    Set<int>? extendedExhaleCycles,
    Set<int>? extendedInhaleCycles,
    double? circleScale,
    double? circleOpacity,
    double? circleBottomScale,
    double? circleBottomOpacity,
    double? deepZoneFill,
    double? topZoneFill,
    // Nullable field: pass () => value to set, omit to keep current.
    PhaseType? Function()? nextPhaseType,
    bool? isNearPhaseEnd,
  }) {
    return BreathingState(
      selectedProgram: selectedProgram ?? this.selectedProgram,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      fillLevel: fillLevel ?? this.fillLevel,
      currentCycle: currentCycle ?? this.currentCycle,
      totalCycles: totalCycles ?? this.totalCycles,
      phaseSecondsRemaining:
          phaseSecondsRemaining ?? this.phaseSecondsRemaining,
      sessionSecondsRemaining:
          sessionSecondsRemaining ?? this.sessionSecondsRemaining,
      showTopCircle: showTopCircle ?? this.showTopCircle,
      showBottomCircle: showBottomCircle ?? this.showBottomCircle,
      extendedExhaleCycles: extendedExhaleCycles ?? this.extendedExhaleCycles,
      extendedInhaleCycles: extendedInhaleCycles ?? this.extendedInhaleCycles,
      circleScale: circleScale ?? this.circleScale,
      circleOpacity: circleOpacity ?? this.circleOpacity,
      circleBottomScale: circleBottomScale ?? this.circleBottomScale,
      circleBottomOpacity: circleBottomOpacity ?? this.circleBottomOpacity,
      deepZoneFill: deepZoneFill ?? this.deepZoneFill,
      topZoneFill: topZoneFill ?? this.topZoneFill,
      nextPhaseType: nextPhaseType != null
          ? nextPhaseType()
          : this.nextPhaseType,
      isNearPhaseEnd: isNearPhaseEnd ?? this.isNearPhaseEnd,
    );
  }

  @override
  List<Object?> get props => [
    selectedProgram,
    status,
    currentPhase,
    fillLevel,
    currentCycle,
    totalCycles,
    phaseSecondsRemaining,
    sessionSecondsRemaining,
    showTopCircle,
    showBottomCircle,
    extendedExhaleCycles,
    extendedInhaleCycles,
    circleScale,
    circleOpacity,
    circleBottomScale,
    circleBottomOpacity,
    deepZoneFill,
    topZoneFill,
    nextPhaseType,
    isNearPhaseEnd,
  ];
}
