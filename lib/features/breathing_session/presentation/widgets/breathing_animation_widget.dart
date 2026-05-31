import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:flutter/material.dart';

class BreathingAnimationWidget extends StatelessWidget {
  const BreathingAnimationWidget({
    required this.fillLevel,
    required this.isAnimating,
    required this.height,
    required this.circleScale,
    required this.circleOpacity,
    required this.circleBottomScale,
    required this.circleBottomOpacity,
    this.showTopCircle = true,
    this.showBottomCircle = true,
    this.isExtendedExhale = false,
    this.deepZoneFill = 0.0,
    this.isExtendedInhale = false,
    this.topZoneFill = 0.0,
    super.key,
  });

  final double fillLevel;
  final bool isAnimating;
  final double height;
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;
  final bool showTopCircle;
  final bool showBottomCircle;

  /// When true, the lower zone is part of the deep-exhale animation.
  final bool isExtendedExhale;

  /// 0.0–1.0: how much of the lower surfaceDim zone has been emptied
  /// during the extension phase of a deep exhale (grows from top to bottom).
  final double deepZoneFill;

  /// When true, the upper zone is part of the deep-inhale animation.
  final bool isExtendedInhale;

  /// 0.0–1.0: how much of the upper surfaceDim zone has been filled
  /// during the extension phase of a deep inhale (grows from bottom to top).
  final double topZoneFill;

  /// Circle diameter as a fraction of bar height.
  static const double kCircleRatio = 0.375;

  /// Gap between circle and bar (px).
  static const double kBarGap = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final circleSize = height * kCircleRatio;
    final radius = height * 0.075;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: showTopCircle ? 1.0 : 0.0,
          child: _buildCircle(circleScale, circleOpacity, circleSize, colors),
        ),
        const SizedBox(height: kBarGap),
        SizedBox(
          height: height,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.signal, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: Column(
                children: [
                  Flexible(
                    flex: 2,
                    child: Stack(
                      children: [
                        Container(color: colors.surfaceDim),
                        if (topZoneFill > 0.0)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: topZoneFill.clamp(0.0, 1.0),
                              child: Container(color: colors.accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 6,
                    child: Stack(
                      children: [
                        Container(color: colors.surface),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: fillLevel.clamp(0.0, 1.0),
                            child: Container(color: colors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Stack(
                      children: [
                        Container(color: colors.surfaceDim),
                        if (deepZoneFill > 0.0)
                          Align(
                            alignment: Alignment.topCenter,
                            child: FractionallySizedBox(
                              heightFactor: deepZoneFill.clamp(0.0, 1.0),
                              child: Container(color: colors.accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: kBarGap),
        Opacity(
          opacity: showBottomCircle ? 1.0 : 0.0,
          child: _buildCircle(
            circleBottomScale,
            circleBottomOpacity,
            circleSize,
            colors,
          ),
        ),
      ],
    );
  }

  Widget _buildCircle(
    double scale,
    double opacity,
    double size,
    BreathscapeColors colors,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
            ),
          ),
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent,
                ),
              ),
            ),
          ),
          // Border als oberstes Element – nie vom Füll-Kreis überdeckt
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.signal, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
