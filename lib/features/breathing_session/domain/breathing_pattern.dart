import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

class BreathingPattern extends Equatable {
  const BreathingPattern({
    required this.name,
    required this.phases,
    this.defaultCycles = 10,
    this.extendedExhaleInterval,
  });

  factory BreathingPattern.fromMap(Map<dynamic, dynamic> map) {
    final rawPhases = map['phases'] as List<dynamic>;
    return BreathingPattern(
      name: map['name'] as String,
      phases: rawPhases
          .cast<Map<dynamic, dynamic>>()
          .map(BreathingPhase.fromMap)
          .toList(),
      defaultCycles: (map['default_cycles'] as int?) ?? 10,
      extendedExhaleInterval: map['extended_exhale_interval'] as int?,
    );
  }

  final String name;
  final List<BreathingPhase> phases;
  final int defaultCycles;

  /// Every Nth cycle uses an extended exhale (exhale + 2 s). Null = disabled.
  final int? extendedExhaleInterval;

  @override
  List<Object?> get props => [
    name,
    phases,
    defaultCycles,
    extendedExhaleInterval,
  ];
}
