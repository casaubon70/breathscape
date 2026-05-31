import 'package:breathscape/features/breathing_session/domain/session_program.dart';
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

final class ProgramSelected extends BreathingEvent {
  const ProgramSelected(this.program);

  final SessionProgram program;

  @override
  List<Object?> get props => [program];
}

/// Internal event — fired exclusively by the Ticker inside BreathingBloc.
final class BreathingTickUpdated extends BreathingEvent {
  const BreathingTickUpdated(this.delta);

  final Duration delta;

  @override
  List<Object?> get props => [delta];
}
