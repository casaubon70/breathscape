import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:equatable/equatable.dart';

enum PatternsStatus { initial, loading, ready, failure }

final class PatternsState extends Equatable {
  const PatternsState({
    this.status = PatternsStatus.initial,
    this.programs = const <SessionProgram>[],
  });

  final PatternsStatus status;
  final List<SessionProgram> programs;

  PatternsState copyWith({
    PatternsStatus? status,
    List<SessionProgram>? programs,
  }) => PatternsState(
    status: status ?? this.status,
    programs: programs ?? this.programs,
  );

  @override
  List<Object?> get props => [status, programs];
}
