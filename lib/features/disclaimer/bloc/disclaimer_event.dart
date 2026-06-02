part of 'disclaimer_bloc.dart';

sealed class DisclaimerEvent extends Equatable {
  const DisclaimerEvent();

  @override
  List<Object?> get props => [];
}

final class DisclaimerCheckRequested extends DisclaimerEvent {
  const DisclaimerCheckRequested();
}

final class DisclaimerAccepted extends DisclaimerEvent {
  const DisclaimerAccepted();
}
