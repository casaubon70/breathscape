import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

/// One concrete breathing cycle with fully resolved phase durations.
final class ResolvedCycle extends Equatable {
  const ResolvedCycle({required this.segmentLabel, required this.phases});

  final String segmentLabel;
  final List<BreathingPhase> phases;

  @override
  List<Object?> get props => [segmentLabel, phases];
}

/// Flat, immutable expansion of a SessionProgram. Created once at session
/// start; the BLoC iterates over it without knowing the program structure.
final class ResolvedTimeline extends Equatable {
  const ResolvedTimeline({required this.name, required this.cycles});

  final String name;

  /// One entry per absolute cycle, in playback order.
  final List<ResolvedCycle> cycles;

  /// Total session length in whole seconds (truncated per phase).
  int get totalSeconds => cycles.fold(
    0,
    (total, cycle) =>
        total + cycle.phases.fold(0, (s, p) => s + p.duration.inSeconds),
  );

  @override
  List<Object?> get props => [name, cycles];
}
