import 'dart:async';

import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/audio/domain/noise_cue_map.dart';
import 'package:breathscape/features/audio/domain/voice_cue_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc({
    AudioPlayer? voicePlayer,
    AudioPlayer? noisePlayerA,
    AudioPlayer? noisePlayerB,
  }) : _voicePlayer = voicePlayer ?? AudioPlayer(),
       _noisePlayerA = noisePlayerA ?? AudioPlayer(),
       _noisePlayerB = noisePlayerB ?? AudioPlayer(),
       super(const AudioState()) {
    on<PlayPhaseVoiceCue>(_onPlayPhaseVoiceCue);
    on<StopVoiceCue>(_onStopVoiceCue);
    on<VoiceMuteToggled>(_onVoiceMuteToggled);
    on<PlayPhaseNoiseCue>(_onPlayPhaseNoiseCue);
    on<StopNoiseCue>(_onStopNoiseCue);
    on<NoiseMuteToggled>(_onNoiseMuteToggled);
  }

  final AudioPlayer _voicePlayer;
  final AudioPlayer _noisePlayerA;
  final AudioPlayer _noisePlayerB;

  // true = A is the current/incoming player, B is outgoing (and vice versa)
  bool _aIsActive = true;

  // Per-player generation counters — incrementing aborts any ongoing fade loop
  // for that player without disturbing the other player's concurrent fade.
  int _genA = 0;
  int _genB = 0;

  static const int _fadeInSteps = 20;
  static const Duration _fadeInStepDuration = Duration(milliseconds: 50);

  static const int _fadeOutSteps = 20;
  static const Duration _fadeOutStepDuration = Duration(milliseconds: 50);

  AudioPlayer get _currentNoisePlayer =>
      _aIsActive ? _noisePlayerA : _noisePlayerB;

  AudioPlayer get _outgoingNoisePlayer =>
      _aIsActive ? _noisePlayerB : _noisePlayerA;

  int _getGen(AudioPlayer player) =>
      identical(player, _noisePlayerA) ? _genA : _genB;

  int _incGen(AudioPlayer player) =>
      identical(player, _noisePlayerA) ? ++_genA : ++_genB;

  @override
  Future<void> close() async {
    await _voicePlayer.dispose();
    await _noisePlayerA.dispose();
    await _noisePlayerB.dispose();
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

    // Capture outgoing player before toggling active side
    final outPlayer = _currentNoisePlayer;
    final outGen = _incGen(outPlayer);

    _aIsActive = !_aIsActive;
    final inPlayer = _currentNoisePlayer;
    final inGen = _incGen(inPlayer);

    // Fade out old player over ~1 s; skip if it was never started
    if (outPlayer.playing) {
      unawaited(_fadeOut(outPlayer, outGen));
    }

    final path = NoiseCueMap.assetPath(event.phase);
    if (path == null) return;

    await inPlayer.setVolume(0);
    await inPlayer.stop();
    await inPlayer.setLoopMode(LoopMode.one);
    await inPlayer.setAsset(path);
    unawaited(inPlayer.play());
    unawaited(_fadeIn(inPlayer, inGen));
  }

  Future<void> _onStopNoiseCue(
    StopNoiseCue event,
    Emitter<AudioState> emit,
  ) async {
    final outgoing = _outgoingNoisePlayer;
    final current = _currentNoisePlayer;

    _incGen(outgoing);
    await outgoing.stop();
    await outgoing.setVolume(1);

    if (current.playing) {
      final outGen = _incGen(current);
      await _fadeOut(current, outGen);
    } else {
      await current.stop();
      await current.setVolume(1);
    }
  }

  Future<void> _onNoiseMuteToggled(
    NoiseMuteToggled event,
    Emitter<AudioState> emit,
  ) async {
    final muting = !state.isNoiseMuted;
    if (muting) {
      final outgoing = _outgoingNoisePlayer;
      final current = _currentNoisePlayer;

      _incGen(outgoing);
      await outgoing.stop();
      await outgoing.setVolume(1);

      if (current.playing) {
        final outGen = _incGen(current);
        await _fadeOut(current, outGen);
      } else {
        await current.stop();
        await current.setVolume(1);
      }
    }
    emit(state.copyWith(isNoiseMuted: muting));
  }

  Future<void> _fadeIn(AudioPlayer player, int gen) async {
    for (var i = 1; i <= _fadeInSteps; i++) {
      if (_getGen(player) != gen) return;
      await player.setVolume(i / _fadeInSteps);
      await Future<void>.delayed(_fadeInStepDuration);
    }
  }

  Future<void> _fadeOut(AudioPlayer player, int gen) async {
    for (var i = _fadeOutSteps - 1; i >= 0; i--) {
      if (_getGen(player) != gen) return;
      await player.setVolume(i / _fadeOutSteps);
      await Future<void>.delayed(_fadeOutStepDuration);
    }
    // Fade completed naturally — stop and reset for future reuse
    if (_getGen(player) == gen) {
      await player.stop();
      await player.setVolume(1);
    }
  }
}
