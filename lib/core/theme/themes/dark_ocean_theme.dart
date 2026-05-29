import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:breathscape/core/theme/data/app_spacing.dart';
import 'package:breathscape/core/theme/data/app_typography.dart';
import 'package:flutter/material.dart';

const _signal = Colors.amber;

const darkOceanTheme = BreathscapeTheme(
  id: 'dark_ocean',
  name: 'Dark Ocean',
  colors: BreathscapeColors(
    background: Color(0xFF0D1B2A),
    surface: Color(0xFF1A2A3A),
    surfaceDim: Color(0xFF0D1520),
    surfaceDropdown: Color(0xFF1A2E42),
    accent: Color(0xFF4A9EBF),
    signal: _signal,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textHint: Colors.white38,
    iconSubtle: Colors.white54,
  ),
  typography: BreathscapeTypography(
    phaseLabel: TextStyle(color: _signal, fontSize: 20, letterSpacing: 2),
    countdown: TextStyle(color: Colors.white38, fontSize: 14),
    dropdownItem: TextStyle(
      color: Colors.white70,
      fontSize: 16,
      letterSpacing: 0.5,
    ),
  ),
  spacing: BreathscapeSpacing(xs: 4, s: 8, m: 16, l: 24, xl: 32, xxl: 48),
);
