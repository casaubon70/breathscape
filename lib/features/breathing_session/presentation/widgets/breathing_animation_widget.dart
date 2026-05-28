import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:flutter/material.dart';

class BreathingAnimationWidget extends StatelessWidget {
  const BreathingAnimationWidget({
    required this.fillLevel,
    required this.isAnimating,
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
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;
  final bool showTopCircle;
  final bool showBottomCircle;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: showTopCircle ? 1.0 : 0.0,
          child: _buildCircle(circleScale, circleOpacity, colors),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.signal, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
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
          child: _buildCircle(circleBottomScale, circleBottomOpacity, colors),
        ),
      ],
    );
  }

  Widget _buildCircle(double scale, double opacity, BreathscapeColors colors) {
    return SizedBox(
      width: 120,
      height: 120,
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
