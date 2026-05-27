abstract class BreathingEvent {
  const BreathingEvent();
}

class PlayPressed extends BreathingEvent {}

class PausePressed extends BreathingEvent {}

class PhaseCompleted extends BreathingEvent {}

class ResetPressed extends BreathingEvent {}

/// Internes Event – wird ausschließlich vom Ticker im BreathingBloc gefeuert.
class BreathingTickUpdated extends BreathingEvent {
  const BreathingTickUpdated(this.delta);
  final Duration delta;
}
