import 'breathing_phase.dart';

class BreathingPattern {
  const BreathingPattern({required this.name, required this.phases});

  final String name;
  final List<BreathingPhase> phases;
}
