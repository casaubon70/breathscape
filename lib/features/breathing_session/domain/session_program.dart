import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/phase_progression.dart';
import 'package:breathscape/features/breathing_session/domain/resolved_timeline.dart';
import 'package:equatable/equatable.dart';

/// A phase definition within a segment: which phase type runs, and how its
/// duration evolves across cycles.
///
/// [interval] applies only to extended phases (`extendedExhale` /
/// `extendedInhale`). When set to N, the extended phase replaces its base
/// phase on every Nth cycle (1-based) within the segment, and is omitted on
/// all other cycles. Null means the spec contributes a phase on every cycle.
final class PhaseSpec extends Equatable {
  const PhaseSpec({
    required this.type,
    required this.progression,
    this.interval,
  });

  factory PhaseSpec.fromJson(Map<String, dynamic> json) => PhaseSpec(
    type: phaseTypeFromString(json['type'] as String),
    progression: PhaseProgression.fromJson(
      json['progression'] as Map<String, dynamic>,
    ),
    interval: json['interval'] as int?,
  );

  final PhaseType type;
  final PhaseProgression progression;

  /// 1-based cadence at which an extended phase fires; null = every cycle.
  final int? interval;

  Map<String, dynamic> toJson() => {
    'type': phaseTypeToString(type),
    'progression': progression.toJson(),
    if (interval != null) 'interval': interval,
  };

  @override
  List<Object?> get props => [type, progression, interval];
}

/// A named group of cycles that all share the same phase structure.
final class SessionSegment extends Equatable {
  const SessionSegment({
    required this.label,
    required this.cycleCount,
    required this.cycleSpec,
  }) : assert(
         cycleCount >= 1 && cycleCount <= 50,
         'cycleCount must be between 1 and 50, got $cycleCount',
       );

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
        // Collect base phase types whose extended replacement fires this cycle.
        final suppressedBases = <PhaseType>{};
        for (final spec in segment.cycleSpec) {
          final iv = spec.interval;
          if (iv == null || iv <= 0) continue;
          final base = _basePhaseFor(spec.type);
          if (base != null && c % iv == 0) suppressedBases.add(base);
        }

        final phases = <BreathingPhase>[];
        for (final spec in segment.cycleSpec) {
          final iv = spec.interval;
          if (iv != null) {
            if (iv <= 0 || c % iv != 0) continue;
          } else if (suppressedBases.contains(spec.type)) {
            continue;
          }
          phases.add(
            BreathingPhase(
              type: spec.type,
              duration: spec.progression.durationFor(c),
            ),
          );
        }

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

/// Maps an extended phase to the base phase it replaces on non-interval
/// cycles. Returns null for non-extended phase types.
PhaseType? _basePhaseFor(PhaseType type) => switch (type) {
  PhaseType.extendedExhale => PhaseType.exhale,
  PhaseType.extendedInhale => PhaseType.inhale,
  _ => null,
};
