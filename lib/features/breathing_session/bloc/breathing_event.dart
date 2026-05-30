import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:equatable/equatable.dart';

sealed class BreathingEvent extends Equatable {
  const BreathingEvent();

  @override
  List<Object?> get props => [];
}

final class PlayPressed extends BreathingEvent {
  const PlayPressed();
}

final class PausePressed extends BreathingEvent {
  const PausePressed();
}

final class ResetPressed extends BreathingEvent {
  const ResetPressed();
}

final class PhaseCompleted extends BreathingEvent {
  const PhaseCompleted();
}

final class PatternSelected extends BreathingEvent {
  const PatternSelected(this.pattern);

  final BreathingPattern pattern;

  @override
  List<Object?> get props => [pattern];
}

/// Aktualisiert nur die Phasendauern des laufenden Patterns ohne Session-Reset.
/// Wird beim Live-Editing von Phasenlängen während einer Session verwendet.
final class PatternDurationUpdated extends BreathingEvent {
  const PatternDurationUpdated(this.pattern);

  final BreathingPattern pattern;

  @override
  List<Object?> get props => [pattern];
}

/// Internes Event – wird ausschließlich vom Ticker im BreathingBloc gefeuert.
final class BreathingTickUpdated extends BreathingEvent {
  const BreathingTickUpdated(this.delta);

  final Duration delta;

  @override
  List<Object?> get props => [delta];
}
