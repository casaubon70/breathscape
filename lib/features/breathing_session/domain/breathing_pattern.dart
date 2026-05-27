import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

class BreathingPattern extends Equatable {
  const BreathingPattern({required this.name, required this.phases});

  factory BreathingPattern.fromMap(Map<dynamic, dynamic> map) {
    final rawPhases = map['phases'] as List<dynamic>;
    return BreathingPattern(
      name: map['name'] as String,
      phases: rawPhases
          .cast<Map<dynamic, dynamic>>()
          .map(BreathingPhase.fromMap)
          .toList(),
    );
  }

  final String name;
  final List<BreathingPhase> phases;

  @override
  List<Object> get props => [name, phases];
}
