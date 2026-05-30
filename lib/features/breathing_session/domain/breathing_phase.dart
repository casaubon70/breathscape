import 'package:equatable/equatable.dart';

enum PhaseType { inhale, holdIn, exhale, extendedExhale, holdOut }

/// Valid editable range for a single phase duration, shared between domain
/// validation (PatternsBloc) and UI controls (PhaseAdjuster).
const int kMinPhaseDurationSeconds = 1;
const int kMaxPhaseDurationSeconds = 99;

class BreathingPhase extends Equatable {
  const BreathingPhase({required this.type, required this.duration});

  factory BreathingPhase.fromMap(Map<dynamic, dynamic> map) {
    return BreathingPhase(
      type: _typeFromString(map['type'] as String),
      duration: Duration(seconds: map['seconds'] as int),
    );
  }

  final PhaseType type;
  final Duration duration;

  static PhaseType _typeFromString(String value) {
    return switch (value) {
      'inhale' => PhaseType.inhale,
      'hold_in' => PhaseType.holdIn,
      'exhale' => PhaseType.exhale,
      'extended_exhale' => PhaseType.extendedExhale,
      'hold_out' => PhaseType.holdOut,
      _ => throw ArgumentError('Unknown phase type: $value'),
    };
  }

  @override
  List<Object> get props => [type, duration];
}
