import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/programs_repository.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatternsBloc extends Bloc<PatternsEvent, PatternsState> {
  PatternsBloc({Future<List<SessionProgram>> Function()? programsLoader})
    : _programsLoader = programsLoader ?? ProgramsRepository.load,
      super(const PatternsState()) {
    on<PatternsLoaded>(_onLoaded);
  }

  final Future<List<SessionProgram>> Function() _programsLoader;

  Future<void> _onLoaded(
    PatternsLoaded event,
    Emitter<PatternsState> emit,
  ) async {
    emit(state.copyWith(status: PatternsStatus.loading));
    try {
      final programs = await _programsLoader();
      emit(state.copyWith(status: PatternsStatus.ready, programs: programs));
    } on Exception {
      emit(state.copyWith(status: PatternsStatus.failure));
    }
  }
}
