import 'package:equatable/equatable.dart';

sealed class PatternsEvent extends Equatable {
  const PatternsEvent();

  @override
  List<Object?> get props => [];
}

final class PatternsLoaded extends PatternsEvent {
  const PatternsLoaded();
}
