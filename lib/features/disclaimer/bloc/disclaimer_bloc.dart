import 'package:breathscape/features/disclaimer/domain/disclaimer_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'disclaimer_event.dart';
part 'disclaimer_state.dart';

class DisclaimerBloc extends Bloc<DisclaimerEvent, DisclaimerState> {
  DisclaimerBloc({required DisclaimerRepository repository})
    : _repository = repository,
      super(const DisclaimerState()) {
    on<DisclaimerCheckRequested>(_onCheckRequested);
    on<DisclaimerAccepted>(_onAccepted);
  }

  final DisclaimerRepository _repository;

  Future<void> _onCheckRequested(
    DisclaimerCheckRequested event,
    Emitter<DisclaimerState> emit,
  ) async {
    emit(state.copyWith(status: DisclaimerStatus.loading));
    final accepted = await _repository.hasAccepted();
    emit(
      state.copyWith(
        status: accepted
            ? DisclaimerStatus.accepted
            : DisclaimerStatus.notAccepted,
      ),
    );
  }

  Future<void> _onAccepted(
    DisclaimerAccepted event,
    Emitter<DisclaimerState> emit,
  ) async {
    await _repository.accept();
    emit(state.copyWith(status: DisclaimerStatus.accepted));
  }
}
