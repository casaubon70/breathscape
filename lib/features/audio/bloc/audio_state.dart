import 'package:equatable/equatable.dart';

enum AudioStatus { idle, playing }

final class AudioState extends Equatable {
  const AudioState({this.status = AudioStatus.idle});

  final AudioStatus status;

  AudioState copyWith({AudioStatus? status}) =>
      AudioState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
