import 'package:flutter/material.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.status,
    required this.onPlay,
    required this.onPause,
  });

  final SessionStatus status;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final isPlaying = status == SessionStatus.playing;
    return IconButton(
      iconSize: 72,
      color: Colors.white,
      icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
      onPressed: isPlaying ? onPause : onPlay,
    );
  }
}
