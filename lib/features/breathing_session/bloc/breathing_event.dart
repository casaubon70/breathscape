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

/// Internes Event – wird ausschließlich vom Ticker im BreathingBloc gefeuert.
final class BreathingTickUpdated extends BreathingEvent {
  const BreathingTickUpdated(this.delta);

  final Duration delta;

  @override
  List<Object?> get props => [delta];
}
