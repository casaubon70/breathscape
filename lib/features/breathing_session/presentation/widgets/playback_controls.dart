import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    required this.status,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    this.onSettings,
    super.key,
  });

  final SessionStatus status;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final isCompleted = status == SessionStatus.completed;
    final isPlaying = status == SessionStatus.playing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 32,
          color: colors.textHint,
          icon: const Icon(Icons.settings),
          onPressed: onSettings,
        ),
        SizedBox(width: spacing.s),
        IconButton(
          iconSize: 72,
          color: isCompleted ? colors.textHint : colors.signal,
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          onPressed: isCompleted ? null : isPlaying ? onPause : onPlay,
        ),
        SizedBox(width: spacing.s),
        IconButton(
          iconSize: 32,
          color: isCompleted ? Colors.black : colors.textHint,
          style: isCompleted
              ? IconButton.styleFrom(backgroundColor: colors.signal)
              : null,
          icon: const Icon(Icons.replay),
          onPressed: onReset,
        ),
      ],
    );
  }
}
