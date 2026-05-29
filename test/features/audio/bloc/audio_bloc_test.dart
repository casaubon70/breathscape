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
  late MockAudioPlayer mockPlayer;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(
      () => mockPlayer.setAsset(
        any(),
        initialPosition: any(named: 'initialPosition'),
      ),
    ).thenAnswer((_) async => null);
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
  });

  AudioBloc buildBloc() => AudioBloc(voicePlayer: mockPlayer);

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
          verify(() => mockPlayer.stop()).called(1);
          verify(
            () => mockPlayer.setAsset('assets/voices/breath_in.mp3'),
          ).called(1);
          verify(() => mockPlayer.play()).called(1);
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
            () => mockPlayer.setAsset('assets/voices/breath_out_deeply.mp3'),
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
          verify(() => mockPlayer.stop()).called(2);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'does not play when muted',
        build: buildBloc,
        seed: () => const AudioState(isMuted: true),
        act: (bloc) => bloc.add(const PlayPhaseVoiceCue(PhaseType.inhale)),
        expect: () => <AudioState>[],
        verify: (_) {
          verifyNever(() => mockPlayer.play());
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
          verify(() => mockPlayer.stop()).called(1);
        },
      );
    });

    group('VoiceMuteToggled', () {
      blocTest<AudioBloc, AudioState>(
        'mutes and stops player when currently unmuted',
        build: buildBloc,
        seed: () => const AudioState(status: AudioStatus.playing),
        act: (bloc) => bloc.add(const VoiceMuteToggled()),
        expect: () => [
          const AudioState(isMuted: true),
        ],
        verify: (_) {
          verify(() => mockPlayer.stop()).called(1);
        },
      );

      blocTest<AudioBloc, AudioState>(
        'unmutes without touching player when currently muted',
        build: buildBloc,
        seed: () => const AudioState(isMuted: true),
        act: (bloc) => bloc.add(const VoiceMuteToggled()),
        expect: () => [const AudioState()],
        verify: (_) {
          verifyNever(() => mockPlayer.stop());
        },
      );
    });
  });
}
