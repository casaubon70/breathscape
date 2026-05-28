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

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final circleSize = height * 0.375;
    final radius = height * 0.075;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: showTopCircle ? 1.0 : 0.0,
          child: _buildCircle(circleScale, circleOpacity, circleSize, colors),
        ),
        const SizedBox(height: 16),
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
                  Flexible(flex: 2, child: Container(color: colors.surfaceDim)),
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
                  Flexible(flex: 2, child: Container(color: colors.surfaceDim)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
