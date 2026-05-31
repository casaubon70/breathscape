import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:equatable/equatable.dart';

enum PatternsStatus { initial, loading, ready, failure }

final class PatternsState extends Equatable {
  const PatternsState({
    this.status = PatternsStatus.initial,
    this.patterns = const [],
  });

  final PatternsStatus status;
  final List<BreathingPattern> patterns;

  PatternsState copyWith({
    PatternsStatus? status,
    List<BreathingPattern>? patterns,
  }) => PatternsState(
    status: status ?? this.status,
    patterns: patterns ?? this.patterns,
  );

  @override
  List<Object?> get props => [status, patterns];
}
