import 'package:equatable/equatable.dart';

enum AudioStatus { idle, playing }

final class AudioState extends Equatable {
  const AudioState({
    this.status = AudioStatus.idle,
    this.isMuted = false,
    this.isNoiseMuted = false,
  });

  final AudioStatus status;
  final bool isMuted;
  final bool isNoiseMuted;

  AudioState copyWith({
    AudioStatus? status,
    bool? isMuted,
    bool? isNoiseMuted,
  }) => AudioState(
    status: status ?? this.status,
    isMuted: isMuted ?? this.isMuted,
    isNoiseMuted: isNoiseMuted ?? this.isNoiseMuted,
  );

  @override
  List<Object?> get props => [status, isMuted, isNoiseMuted];
}
