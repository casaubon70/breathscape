import 'package:equatable/equatable.dart';

sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

final class ThemeChanged extends ThemeEvent {
  const ThemeChanged(this.themeId);

  final String themeId;

  @override
  List<Object?> get props => [themeId];
}
