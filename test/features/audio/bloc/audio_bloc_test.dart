import 'package:bloc_test/bloc_test.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  setUpAll(() => registerFallbackValue(LoopMode.off));

  late MockAudioPlayer mockVoicePlayer;
  late MockAudioPlayer mockNoisePlayerA;
  late MockAudioPlayer mockNoisePlayerB;

  void stubPlayer(MockAudioPlayer p, {bool playing = false}) {
    when(() => p.stop()).thenAnswer((_) async {});
    when(() => p.play()).thenAnswer((_) async {});
    when(
      () => p.setAsset(any(), initialPosition: any(named: 'initialPosition')),
    ).thenAnswer((_) async => null);
    when(() => p.dispose()).thenAnswer((_) async {});
    when(() => p.setVolume(any())).thenAnswer((_) async {});
    when(() => p.setLoopMode(any())).thenAnswer((_) async {});
    when(() => p.volume).thenReturn(1);
    when(() => p.playing).thenReturn(playing);
  }

  setUp(() {
    mockVoicePlayer = MockAudioPlayer();
    mockNoisePlayerA = MockAudioPlayer();
    mockNoisePlayerB = MockAudioPlayer();
    stubPlayer(mockVoicePlayer);
    stubPlayer(mockNoisePlayerA);
    stubPlayer(mockNoisePlayerB);
  });

  AudioBloc buildBloc() => AudioBloc(
    voicePlayer: mockVoicePlayer,
    noisePlayerA: mockNoisePlayerA,
    noisePlayerB: mockNoisePlayerB,
  );

  group('AudioBloc', () {
    test('initial state is AudioState(idle)', () {
      expect(buildBloc().state, const AudioState());
    });

    group('PlayPhaseVoiceCue', () {
      blocTest<AudioBloc, AudioState>(
        'emits [playing] and calls stop → setAsset → play for inhale',
        build: buildBloc,
        act: (bloc) => bloc.add(const PlayPhaseVoiceCue(PhaseType.inhale)),
        expect: () => [const AudioState(status: AudioStatus.playing)],
        verify: (_) {
          verify(() => mockVoicePlayer.stop()).called(1);
          verify(
            () => mockVoicePlayer.setAsset('assets/voices/breath_in.mp3'),
          ).called(1);
          verify(() => mockVoicePlayer.play()).called(1);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'emits [playing] for extendedExhale with correct asset',
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const PlayPhaseVoiceCue(PhaseType.extendedExhale)),
        expect: () => [const AudioState(status: AudioStatus.playing)],
        verify: (_) {
          verify(
            () =>
                mockVoicePlayer.setAsset('assets/voices/breath_out_deeply.mp3'),
          ).called(1);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'stops previous sound before playing new cue',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const PlayPhaseVoiceCue(PhaseType.inhale));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const PlayPhaseVoiceCue(PhaseType.exhale));
        },
        verify: (_) {
          verify(() => mockVoicePlayer.stop()).called(2);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'does not play when muted',
        build: buildBloc,
        seed: () => const AudioState(isMuted: true),
        act: (bloc) => bloc.add(const PlayPhaseVoiceCue(PhaseType.inhale)),
        expect: () => <AudioState>[],
        verify: (_) {
          verifyNever(() => mockVoicePlayer.play());
        },
      );
    });

    group('StopVoiceCue', () {
      blocTest<AudioBloc, AudioState>(
        'emits [idle] and calls stop',
        build: buildBloc,
        seed: () => const AudioState(status: AudioStatus.playing),
        act: (bloc) => bloc.add(const StopVoiceCue()),
        expect: () => [const AudioState()],
        verify: (_) {
          verify(() => mockVoicePlayer.stop()).called(1);
        },
      );
    });

    group('VoiceMuteToggled', () {
      blocTest<AudioBloc, AudioState>(
        'mutes and stops player when currently unmuted',
        build: buildBloc,
        seed: () => const AudioState(status: AudioStatus.playing),
        act: (bloc) => bloc.add(const VoiceMuteToggled()),
        expect: () => [const AudioState(isMuted: true)],
        verify: (_) {
          verify(() => mockVoicePlayer.stop()).called(1);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'unmutes without touching player when currently muted',
        build: buildBloc,
        seed: () => const AudioState(isMuted: true),
        act: (bloc) => bloc.add(const VoiceMuteToggled()),
        expect: () => [const AudioState()],
        verify: (_) {
          verifyNever(() => mockVoicePlayer.stop());
        },
      );
    });

    group('PlayPhaseNoiseCue', () {
      blocTest<AudioBloc, AudioState>(
        'plays inhale noise on noisePlayerB (first call uses B as incoming)',
        build: buildBloc,
        act: (bloc) => bloc.add(const PlayPhaseNoiseCue(PhaseType.inhale)),
        verify: (_) {
          verify(
            () => mockNoisePlayerB.setAsset('assets/noises/inhale.mp3'),
          ).called(1);
          verify(() => mockNoisePlayerB.play()).called(1);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'does not play when noise muted',
        build: buildBloc,
        seed: () => const AudioState(isNoiseMuted: true),
        act: (bloc) => bloc.add(const PlayPhaseNoiseCue(PhaseType.inhale)),
        verify: (_) {
          verifyNever(() => mockNoisePlayerA.play());
          verifyNever(() => mockNoisePlayerB.play());
        },
      );

      blocTest<AudioBloc, AudioState>(
        'fades out previous player if it was playing',
        build: () {
          stubPlayer(mockNoisePlayerA, playing: true);
          return AudioBloc(
            voicePlayer: mockVoicePlayer,
            noisePlayerA: mockNoisePlayerA,
            noisePlayerB: mockNoisePlayerB,
          );
        },
        act: (bloc) => bloc.add(const PlayPhaseNoiseCue(PhaseType.inhale)),
        verify: (_) {
          // noisePlayerA (outgoing) receives volume-down calls for fade-out
          verify(
            () => mockNoisePlayerA.setVolume(any()),
          ).called(greaterThan(0));
        },
      );
    });

    group('NoiseMuteToggled', () {
      blocTest<AudioBloc, AudioState>(
        'emits isNoiseMuted=true when currently unmuted',
        build: buildBloc,
        act: (bloc) => bloc.add(const NoiseMuteToggled()),
        expect: () => [const AudioState(isNoiseMuted: true)],
      );

      blocTest<AudioBloc, AudioState>(
        'emits isNoiseMuted=false when currently muted',
        build: buildBloc,
        seed: () => const AudioState(isNoiseMuted: true),
        act: (bloc) => bloc.add(const NoiseMuteToggled()),
        expect: () => [const AudioState()],
      );
    });
  });
}
