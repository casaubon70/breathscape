part of 'disclaimer_bloc.dart';

enum DisclaimerStatus { initial, loading, accepted, notAccepted }

final class DisclaimerState extends Equatable {
  const DisclaimerState({this.status = DisclaimerStatus.initial});

  final DisclaimerStatus status;

  DisclaimerState copyWith({DisclaimerStatus? status}) =>
      DisclaimerState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
