import 'package:equatable/equatable.dart';

enum PhaseType {
  inhale,
  extendedInhale,
  holdIn,
  exhale,
  extendedExhale,
  holdOut,
}

/// Valid editable range for a single phase duration, shared between domain
/// validation (PatternsBloc) and UI controls (PhaseAdjuster).
const int kMinPhaseDurationSeconds = 1;
const int kMaxPhaseDurationSeconds = 99;

PhaseType phaseTypeFromString(String value) => switch (value) {
  'inhale' => PhaseType.inhale,
  'hold_in' => PhaseType.holdIn,
  'exhale' => PhaseType.exhale,
  'extended_inhale' => PhaseType.extendedInhale,
  'extended_exhale' => PhaseType.extendedExhale,
  'hold_out' => PhaseType.holdOut,
  _ => throw ArgumentError('Unknown phase type: $value'),
};

String phaseTypeToString(PhaseType type) => switch (type) {
  PhaseType.inhale => 'inhale',
  PhaseType.holdIn => 'hold_in',
  PhaseType.exhale => 'exhale',
  PhaseType.extendedInhale => 'extended_inhale',
  PhaseType.extendedExhale => 'extended_exhale',
  PhaseType.holdOut => 'hold_out',
};

class BreathingPhase extends Equatable {
  const BreathingPhase({required this.type, required this.duration});

  factory BreathingPhase.fromMap(Map<dynamic, dynamic> map) {
    return BreathingPhase(
      type: phaseTypeFromString(map['type'] as String),
      duration: Duration(seconds: map['seconds'] as int),
    );
  }

  final PhaseType type;
  final Duration duration;

  @override
  List<Object> get props => [type, duration];
}
