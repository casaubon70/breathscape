import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/resolved_timeline.dart';
import 'package:equatable/equatable.dart';

/// A phase definition within a segment: which phase type runs, and how its
/// duration evolves across cycles.
final class PhaseSpec extends Equatable {
  const PhaseSpec({required this.type, required this.progression});

  factory PhaseSpec.fromJson(Map<String, dynamic> json) => PhaseSpec(
    type: phaseTypeFromString(json['type'] as String),
    progression: PhaseProgression.fromJson(
      json['progression'] as Map<String, dynamic>,
    ),
  );

  final PhaseType type;
  final PhaseProgression progression;

  Map<String, dynamic> toJson() => {
    'type': phaseTypeToString(type),
    'progression': progression.toJson(),
  };

  @override
  List<Object?> get props => [type, progression];
}

/// A named group of cycles that all share the same phase structure.
final class SessionSegment extends Equatable {
  const SessionSegment({
    required this.label,
    required this.cycleCount,
    required this.cycleSpec,
  });

  factory SessionSegment.fromJson(Map<String, dynamic> json) {
    final rawCycleSpec = json['cycleSpec'] as List<dynamic>;
    return SessionSegment(
      label: json['label'] as String,
      cycleCount: json['cycleCount'] as int,
      cycleSpec: rawCycleSpec
          .map((raw) => PhaseSpec.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }

  final String label;
  final int cycleCount;
  final List<PhaseSpec> cycleSpec;

  Map<String, dynamic> toJson() => {
    'label': label,
    'cycleCount': cycleCount,
    'cycleSpec': cycleSpec.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [label, cycleCount, cycleSpec];
}

/// Top-level session definition: an ordered list of segments that together
/// form a complete breathing session.
final class SessionProgram extends Equatable {
  const SessionProgram({required this.name, required this.segments});

  factory SessionProgram.fromJson(Map<String, dynamic> json) => SessionProgram(
    name: json['name'] as String,
    segments: (json['segments'] as List<dynamic>)
        .map((s) => SessionSegment.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  final String name;
  final List<SessionSegment> segments;

  int get totalCycles => segments.fold(0, (sum, seg) => sum + seg.cycleCount);

  /// Expands all segments into a flat [ResolvedTimeline] with concrete phase
  /// durations. Called once at session start; the result is immutable.
  ResolvedTimeline resolve() {
    final cycles = <ResolvedCycle>[];
    for (final segment in segments) {
      for (var c = 0; c < segment.cycleCount; c++) {
        final phases = segment.cycleSpec.map((spec) {
          return BreathingPhase(
            type: spec.type,
            duration: spec.progression.durationFor(c),
          );
        }).toList();
        cycles.add(ResolvedCycle(segmentLabel: segment.label, phases: phases));
      }
    }
    return ResolvedTimeline(name: name, cycles: cycles);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'segments': segments.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [name, segments];
}
