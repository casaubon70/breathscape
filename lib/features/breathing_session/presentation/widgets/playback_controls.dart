import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    required this.status,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    super.key,
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
