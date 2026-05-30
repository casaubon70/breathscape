import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:equatable/equatable.dart';

sealed class PatternsEvent extends Equatable {
  const PatternsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads base patterns and persisted overrides; emits the merged list.
final class PatternsLoaded extends PatternsEvent {
  const PatternsLoaded();
}

/// User changed the duration of a single phase of a pattern.
final class PhaseSecondsEdited extends PatternsEvent {
  const PhaseSecondsEdited({
    required this.patternName,
    required this.phaseIndex,
    required this.seconds,
  });

  final String patternName;
  final int phaseIndex;
  final int seconds;

  @override
  List<Object?> get props => [patternName, phaseIndex, seconds];
}

/// User reset a pattern back to its bundled defaults.
final class PatternReset extends PatternsEvent {
  const PatternReset(this.patternName);

  final String patternName;

  @override
  List<Object?> get props => [patternName];
}

/// Internal — overrides arrived from another device via the sync store.
final class RemoteOverridesReceived extends PatternsEvent {
  const RemoteOverridesReceived(this.overrides);

  final PatternOverrides overrides;

  @override
  List<Object?> get props => [overrides];
}
