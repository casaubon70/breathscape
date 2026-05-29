import 'package:breathscape/core/theme/app_theme.dart';
import 'package:equatable/equatable.dart';

final class ThemeState extends Equatable {
  const ThemeState({required this.theme});

  final BreathscapeTheme theme;

  ThemeState copyWith({BreathscapeTheme? theme}) =>
      ThemeState(theme: theme ?? this.theme);

  @override
  List<Object?> get props => [theme.id];
}
