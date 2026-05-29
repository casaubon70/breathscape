import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceMuteButton extends StatelessWidget {
  const VoiceMuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return BlocBuilder<AudioBloc, AudioState>(
      buildWhen: (prev, curr) => prev.isMuted != curr.isMuted,
      builder: (context, state) {
        return IconButton(
          onPressed: () =>
              context.read<AudioBloc>().add(const VoiceMuteToggled()),
          icon: Icon(
            state.isMuted
                ? Icons.voice_over_off_outlined
                : Icons.record_voice_over_outlined,
            color: state.isMuted ? colors.textHint : colors.accent,
          ),
          tooltip: state.isMuted ? 'Voice cues off' : 'Voice cues on',
        );
      },
    );
  }
}
