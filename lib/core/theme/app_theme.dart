import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:breathscape/core/theme/data/app_spacing.dart';
import 'package:breathscape/core/theme/data/app_typography.dart';
import 'package:flutter/material.dart';

final class BreathscapeTheme {
  const BreathscapeTheme({
    required this.id,
    required this.name,
    required this.colors,
    required this.typography,
    required this.spacing,
  });

  final String id;
  final String name;
  final BreathscapeColors colors;
  final BreathscapeTypography typography;
  final BreathscapeSpacing spacing;

  ThemeData toThemeData() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: colors.background,
      iconTheme: const IconThemeData(size: 22),
      extensions: [
        BreathscapeThemeExtension(
          colors: colors,
          typography: typography,
          spacing: spacing,
        ),
      ],
    );
  }
}

final class BreathscapeThemeExtension
    extends ThemeExtension<BreathscapeThemeExtension> {
  const BreathscapeThemeExtension({
    required this.colors,
    required this.typography,
    required this.spacing,
  });

  final BreathscapeColors colors;
  final BreathscapeTypography typography;
  final BreathscapeSpacing spacing;

  @override
  BreathscapeThemeExtension copyWith({
    BreathscapeColors? colors,
    BreathscapeTypography? typography,
    BreathscapeSpacing? spacing,
  }) => BreathscapeThemeExtension(
    colors: colors ?? this.colors,
    typography: typography ?? this.typography,
    spacing: spacing ?? this.spacing,
  );

  @override
  BreathscapeThemeExtension lerp(
    ThemeExtension<BreathscapeThemeExtension>? other,
    double t,
  ) {
    if (other is! BreathscapeThemeExtension) return this;
    // Tokens sind diskret – kein Lerp zwischen Themes
    return this;
  }
}

extension BreathscapeThemeX on BuildContext {
  BreathscapeThemeExtension get bTheme =>
      Theme.of(this).extension<BreathscapeThemeExtension>()!;
}
