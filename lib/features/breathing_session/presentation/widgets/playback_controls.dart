import 'package:flutter/material.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.status,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
  });

  final SessionStatus status;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isPlaying = status == SessionStatus.playing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 72,
          color: Colors.white,
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          onPressed: isPlaying ? onPause : onPlay,
        ),
        const SizedBox(width: 8),
        IconButton(
          iconSize: 32,
          color: Colors.white38,
          icon: const Icon(Icons.refresh),
          onPressed: onReset,
        ),
      ],
    );
  }
}
