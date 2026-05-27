enum PhaseType { inhale, holdIn, exhale, holdOut }

class BreathingPhase {
  const BreathingPhase({required this.type, required this.duration});

  final PhaseType type;
  final Duration duration;
}
