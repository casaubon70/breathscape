import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:equatable/equatable.dart';

/// User-defined per-phase second overrides for built-in patterns.
///
/// Identity is `pattern name → { phase index → seconds }`. Only base phase
/// durations are overridable; derived phases (e.g. extended exhale) stay
/// computed at runtime.
class PatternOverrides extends Equatable {
  const PatternOverrides({this.byPattern = const {}, this.updatedAt = 0});

  factory PatternOverrides.fromJson(Map<String, dynamic> json) {
    final rawOverrides = json['overrides'] as Map<String, dynamic>? ?? {};
    final byPattern = <String, Map<int, int>>{};
    for (final entry in rawOverrides.entries) {
      final phases = (entry.value as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      );
      byPattern[entry.key] = phases;
    }
    return PatternOverrides(
      byPattern: byPattern,
      updatedAt: (json['updatedAt'] as int?) ?? 0,
    );
  }

  /// `pattern name → { phase index → seconds }`.
  final Map<String, Map<int, int>> byPattern;

  /// Epoch milliseconds of the last write — used for last-writer-wins merge.
  final int updatedAt;

  bool get isEmpty => byPattern.isEmpty;

  Map<String, dynamic> toJson() => {
    'updatedAt': updatedAt,
    'overrides': byPattern.map(
      (name, phases) => MapEntry(
        name,
        phases.map((index, seconds) => MapEntry(index.toString(), seconds)),
      ),
    ),
  };

  /// Returns a copy with [seconds] set for [phaseIndex] of [patternName],
  /// stamped with [updatedAt].
  PatternOverrides withPhaseSeconds(
    String patternName,
    int phaseIndex,
    int seconds, {
    required int updatedAt,
  }) {
    final next = {
      for (final entry in byPattern.entries) entry.key: {...entry.value},
    };
    (next[patternName] ??= {})[phaseIndex] = seconds;
    return PatternOverrides(byPattern: next, updatedAt: updatedAt);
  }

  /// Returns a copy with all overrides for [patternName] removed, stamped with
  /// [updatedAt].
  PatternOverrides withoutPattern(
    String patternName, {
    required int updatedAt,
  }) {
    final next = {
      for (final entry in byPattern.entries)
        if (entry.key != patternName) entry.key: {...entry.value},
    };
    return PatternOverrides(byPattern: next, updatedAt: updatedAt);
  }

  @override
  List<Object?> get props => [byPattern, updatedAt];
}

/// Applies [overrides] to [base], replacing matching phase durations by index.
/// Patterns and phases without an override are returned unchanged.
List<BreathingPattern> applyOverrides(
  List<BreathingPattern> base,
  PatternOverrides overrides,
) {
  if (overrides.isEmpty) return base;
  return base.map((pattern) {
    final phaseOverrides = overrides.byPattern[pattern.name];
    if (phaseOverrides == null || phaseOverrides.isEmpty) return pattern;
    final phases = <BreathingPhase>[];
    for (var i = 0; i < pattern.phases.length; i++) {
      final seconds = phaseOverrides[i];
      final phase = pattern.phases[i];
      phases.add(
        seconds == null
            ? phase
            : BreathingPhase(
                type: phase.type,
                duration: Duration(seconds: seconds),
              ),
      );
    }
    return BreathingPattern(
      name: pattern.name,
      phases: phases,
      defaultCycles: pattern.defaultCycles,
      extendedExhaleInterval: pattern.extendedExhaleInterval,
    );
  }).toList();
}
