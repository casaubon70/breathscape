import 'dart:async';

import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/audio/domain/voice_cue_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc({AudioPlayer? voicePlayer})
    : _voicePlayer = voicePlayer ?? AudioPlayer(),
      super(const AudioState()) {
    on<PlayPhaseVoiceCue>(_onPlayPhaseVoiceCue);
    on<StopVoiceCue>(_onStopVoiceCue);
  }

  final AudioPlayer _voicePlayer;

  @override
  Future<void> close() async {
    await _voicePlayer.dispose();
    return super.close();
  }

  Future<void> _onPlayPhaseVoiceCue(
    PlayPhaseVoiceCue event,
    Emitter<AudioState> emit,
  ) async {
    final path = VoiceCueMap.assetPath(event.phase);
    if (path == null) return;

    await _voicePlayer.stop();
    await _voicePlayer.setAsset(path);
    unawaited(_voicePlayer.play());
    emit(state.copyWith(status: AudioStatus.playing));
  }

  Future<void> _onStopVoiceCue(
    StopVoiceCue event,
    Emitter<AudioState> emit,
  ) async {
    await _voicePlayer.stop();
    emit(state.copyWith(status: AudioStatus.idle));
  }
}
