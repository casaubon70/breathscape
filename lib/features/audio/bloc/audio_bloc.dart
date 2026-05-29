import 'dart:async';

import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/audio/domain/noise_cue_map.dart';
import 'package:breathscape/features/audio/domain/voice_cue_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc({AudioPlayer? voicePlayer, AudioPlayer? noisePlayer})
    : _voicePlayer = voicePlayer ?? AudioPlayer(),
      _noisePlayer = noisePlayer ?? AudioPlayer(),
      super(const AudioState()) {
    on<PlayPhaseVoiceCue>(_onPlayPhaseVoiceCue);
    on<StopVoiceCue>(_onStopVoiceCue);
    on<VoiceMuteToggled>(_onVoiceMuteToggled);
    on<PlayPhaseNoiseCue>(_onPlayPhaseNoiseCue);
    on<StopNoiseCue>(_onStopNoiseCue);
    on<NoiseMuteToggled>(_onNoiseMuteToggled);
  }

  final AudioPlayer _voicePlayer;
  final AudioPlayer _noisePlayer;

  // Incremented on every noise fade start; lets an older fade abort itself
  // when a newer one takes over.
  int _fadeGeneration = 0;

  static const int _fadeSteps = 10;
  static const Duration _fadeStepDuration = Duration(milliseconds: 25);

  @override
  Future<void> close() async {
    await _voicePlayer.dispose();
    await _noisePlayer.dispose();
    return super.close();
  }

  Future<void> _onPlayPhaseVoiceCue(
    PlayPhaseVoiceCue event,
    Emitter<AudioState> emit,
  ) async {
    if (state.isMuted) return;
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

  Future<void> _onVoiceMuteToggled(
    VoiceMuteToggled event,
    Emitter<AudioState> emit,
  ) async {
    final muting = !state.isMuted;
    if (muting) await _voicePlayer.stop();
    emit(
      state.copyWith(
        isMuted: muting,
        status: muting ? AudioStatus.idle : state.status,
      ),
    );
  }

  Future<void> _onPlayPhaseNoiseCue(
    PlayPhaseNoiseCue event,
    Emitter<AudioState> emit,
  ) async {
    if (state.isNoiseMuted) return;
    final path = NoiseCueMap.assetPath(event.phase);
    if (path == null) return;

    final gen = ++_fadeGeneration;
    await _noisePlayer.setVolume(0);
    await _noisePlayer.stop();
    await _noisePlayer.setLoopMode(LoopMode.one);
    await _noisePlayer.setAsset(path);
    unawaited(_noisePlayer.play());
    unawaited(_fadeIn(_noisePlayer, gen));
  }

  Future<void> _onStopNoiseCue(
    StopNoiseCue event,
    Emitter<AudioState> emit,
  ) async {
    final gen = ++_fadeGeneration;
    await _fadeOut(_noisePlayer, gen);
    await _noisePlayer.stop();
    await _noisePlayer.setVolume(1);
  }

  Future<void> _onNoiseMuteToggled(
    NoiseMuteToggled event,
    Emitter<AudioState> emit,
  ) async {
    final muting = !state.isNoiseMuted;
    if (muting) {
      final gen = ++_fadeGeneration;
      await _fadeOut(_noisePlayer, gen);
      await _noisePlayer.stop();
      await _noisePlayer.setVolume(1);
    }
    emit(state.copyWith(isNoiseMuted: muting));
  }

  Future<void> _fadeIn(AudioPlayer player, int gen) async {
    for (var i = 1; i <= _fadeSteps; i++) {
      if (_fadeGeneration != gen) return;
      await player.setVolume(i / _fadeSteps);
      await Future<void>.delayed(_fadeStepDuration);
    }
  }

  Future<void> _fadeOut(AudioPlayer player, int gen) async {
    for (var i = _fadeSteps - 1; i >= 0; i--) {
      if (_fadeGeneration != gen) return;
      await player.setVolume(i / _fadeSteps);
      await Future<void>.delayed(_fadeStepDuration);
    }
  }
}
