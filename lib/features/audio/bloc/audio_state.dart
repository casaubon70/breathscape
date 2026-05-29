import 'package:equatable/equatable.dart';

enum AudioStatus { idle, playing }

final class AudioState extends Equatable {
  const AudioState({this.status = AudioStatus.idle, this.isMuted = false});

  final AudioStatus status;
  final bool isMuted;

  AudioState copyWith({AudioStatus? status, bool? isMuted}) => AudioState(
    status: status ?? this.status,
    isMuted: isMuted ?? this.isMuted,
  );

  @override
  List<Object?> get props => [status, isMuted];
}
