import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/patterns_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatternsBloc extends Bloc<PatternsEvent, PatternsState> {
  PatternsBloc({Future<List<BreathingPattern>> Function()? baseLoader})
    : _baseLoader = baseLoader ?? PatternsRepository.load,
      super(const PatternsState()) {
    on<PatternsLoaded>(_onLoaded);
  }

  final Future<List<BreathingPattern>> Function() _baseLoader;

  Future<void> _onLoaded(
    PatternsLoaded event,
    Emitter<PatternsState> emit,
  ) async {
    emit(state.copyWith(status: PatternsStatus.loading));
    try {
      final patterns = await _baseLoader();
      emit(state.copyWith(status: PatternsStatus.ready, patterns: patterns));
    } on Exception {
      emit(state.copyWith(status: PatternsStatus.failure));
    }
  }
}
