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

    // Row fills the outer Stack's width (supplied via tight constraints from
    // SizedBox + StackFit.expand, or loose constraints that Expanded fills).
    // Expanded on both sides guarantees pixel-perfect centering.
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: spacing.s),
              child: IconButton(
                iconSize: 32,
                color: colors.textHint,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.settings),
                onPressed: onSettings,
              ),
            ),
          ),
        ),
        SizedBox.square(
          dimension: 72,
          child: IconButton(
            iconSize: 72,
            color: isCompleted ? colors.textHint : colors.signal,
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: isCompleted ? null : isPlaying ? onPause : onPlay,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: spacing.s),
              child: IconButton(
                iconSize: 32,
                color: isCompleted ? Colors.black : colors.textHint,
                style: isCompleted
                    ? IconButton.styleFrom(
                        backgroundColor: colors.signal,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                icon: const Icon(Icons.replay),
                onPressed: onReset,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
