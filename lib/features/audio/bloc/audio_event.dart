import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

sealed class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

final class PlayPhaseVoiceCue extends AudioEvent {
  const PlayPhaseVoiceCue(this.phase);

  final PhaseType phase;

  @override
  List<Object?> get props => [phase];
}

final class StopVoiceCue extends AudioEvent {
  const StopVoiceCue();
}

final class VoiceMuteToggled extends AudioEvent {
  const VoiceMuteToggled();
}

final class PlayPhaseNoiseCue extends AudioEvent {
  const PlayPhaseNoiseCue(this.phase);

  final PhaseType phase;

  @override
  List<Object?> get props => [phase];
}

final class StopNoiseCue extends AudioEvent {
  const StopNoiseCue();
}

final class NoiseMuteToggled extends AudioEvent {
  const NoiseMuteToggled();
}
