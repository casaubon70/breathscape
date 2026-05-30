import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides.dart';
import 'package:equatable/equatable.dart';

enum PatternsStatus { initial, loading, ready, failure }

final class PatternsState extends Equatable {
  const PatternsState({
    this.status = PatternsStatus.initial,
    this.patterns = const [],
    this.overrides = const PatternOverrides(),
  });

  final PatternsStatus status;

  /// Base patterns with user overrides already applied.
  final List<BreathingPattern> patterns;

  final PatternOverrides overrides;

  PatternsState copyWith({
    PatternsStatus? status,
    List<BreathingPattern>? patterns,
    PatternOverrides? overrides,
  }) => PatternsState(
    status: status ?? this.status,
    patterns: patterns ?? this.patterns,
    overrides: overrides ?? this.overrides,
  );

  @override
  List<Object?> get props => [status, patterns, overrides];
}
