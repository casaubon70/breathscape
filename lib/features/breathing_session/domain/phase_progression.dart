import 'package:equatable/equatable.dart';

/// Determines the duration of a single phase for a given cycle within a
/// segment. Sealed so that all variants are known at compile time.
sealed class PhaseProgression extends Equatable {
  const PhaseProgression();

  factory PhaseProgression.fromJson(Map<String, dynamic> json) {
    return switch (json['kind'] as String) {
      'fixed' => FixedProgression.fromJson(json),
      'linear' => LinearProgression.fromJson(json),
      'steps' => StepProgression.fromJson(json),
      final k => throw ArgumentError('Unknown progression kind: $k'),
    };
  }

  /// Returns the duration this phase should have for [cycleInSegment]
  /// (0-based index within the segment).
  Duration durationFor(int cycleInSegment);

  Map<String, dynamic> toJson();
}

/// Constant duration — direct replacement for the old BreathingPhase.duration.
final class FixedProgression extends PhaseProgression {
  const FixedProgression(this.duration);

  factory FixedProgression.fromJson(Map<String, dynamic> json) =>
      FixedProgression(
        Duration(
          milliseconds: ((json['seconds'] as num) * 1000).round(),
        ),
      );

  final Duration duration;

  @override
  Duration durationFor(int cycleInSegment) => duration;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'fixed',
    'seconds': duration.inMilliseconds / 1000,
  };

  @override
  List<Object?> get props => [duration];
}

/// Duration increases (or decreases) linearly with each cycle.
/// Example: holdIn starts at 4 s, grows by 0.5 s per cycle, capped at 6 s.
final class LinearProgression extends PhaseProgression {
  const LinearProgression({
    required this.start,
    required this.step,
    this.max,
    this.min,
  });

  factory LinearProgression.fromJson(Map<String, dynamic> json) {
    final rawMax = json['maxSeconds'];
    final rawMin = json['minSeconds'];
    return LinearProgression(
      start: Duration(
        milliseconds: ((json['startSeconds'] as num) * 1000).round(),
      ),
      step: Duration(
        milliseconds: ((json['stepSeconds'] as num) * 1000).round(),
      ),
      max: rawMax == null
          ? null
          : Duration(milliseconds: ((rawMax as num) * 1000).round()),
      min: rawMin == null
          ? null
          : Duration(milliseconds: ((rawMin as num) * 1000).round()),
    );
  }

  final Duration start;

  /// May be negative for a decreasing progression.
  final Duration step;

  final Duration? max;
  final Duration? min;

  @override
  Duration durationFor(int cycleInSegment) {
    var ms = start.inMilliseconds + step.inMilliseconds * cycleInSegment;
    final cap = max;
    final floor = min;
    if (cap != null && ms > cap.inMilliseconds) ms = cap.inMilliseconds;
    if (floor != null && ms < floor.inMilliseconds) ms = floor.inMilliseconds;
    return Duration(milliseconds: ms);
  }

  @override
  Map<String, dynamic> toJson() {
    final cap = max;
    final floor = min;
    return {
      'kind': 'linear',
      'startSeconds': start.inMilliseconds / 1000,
      'stepSeconds': step.inMilliseconds / 1000,
      if (cap != null) 'maxSeconds': cap.inMilliseconds / 1000,
      if (floor != null) 'minSeconds': floor.inMilliseconds / 1000,
    };
  }

  @override
  List<Object?> get props => [start, step, max, min];
}

/// Explicit duration per cycle index; the last value repeats for any
/// cycle beyond the list length. Use for alternating or step-function patterns.
final class StepProgression extends PhaseProgression {
  const StepProgression(this.durations);

  factory StepProgression.fromJson(Map<String, dynamic> json) =>
      StepProgression(
        (json['seconds'] as List<dynamic>)
            .map((s) => Duration(milliseconds: ((s as num) * 1000).round()))
            .toList(),
      );

  final List<Duration> durations;

  @override
  Duration durationFor(int cycleInSegment) =>
      durations[cycleInSegment.clamp(0, durations.length - 1)];

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'steps',
    'seconds': durations.map((d) => d.inMilliseconds / 1000).toList(),
  };

  @override
  List<Object?> get props => [durations];
}
