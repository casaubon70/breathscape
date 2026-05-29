import 'package:breathscape/core/theme/bloc/theme_event.dart';
import 'package:breathscape/core/theme/bloc/theme_state.dart';
import 'package:breathscape/core/theme/themes/dark_ocean_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(theme: darkOceanTheme)) {
    on<ThemeChanged>(_onThemeChanged);
  }

  static const _themes = {'dark_ocean': darkOceanTheme};

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    final theme = _themes[event.themeId];
    if (theme != null) emit(state.copyWith(theme: theme));
  }
}
