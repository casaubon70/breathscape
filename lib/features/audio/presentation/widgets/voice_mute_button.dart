import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/bloc/audio_state.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VoiceMuteButton extends StatelessWidget {
  const VoiceMuteButton({super.key});

  static const double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return BlocBuilder<AudioBloc, AudioState>(
      buildWhen: (prev, curr) => prev.isMuted != curr.isMuted,
      builder: (context, state) {
        return IconButton(
          onPressed: () =>
              context.read<AudioBloc>().add(const VoiceMuteToggled()),
          iconSize: _iconSize,
          icon: FaIcon(
            state.isMuted
                ? FontAwesomeIcons.commentSlash
                : FontAwesomeIcons.commentDots,
            size: _iconSize,
            color: state.isMuted ? colors.textHint : colors.signal,
          ),
          tooltip: state.isMuted
              ? AppLocalizations.of(context)!.voiceCuesOff
              : AppLocalizations.of(context)!.voiceCuesOn,
        );
      },
    );
  }
}
