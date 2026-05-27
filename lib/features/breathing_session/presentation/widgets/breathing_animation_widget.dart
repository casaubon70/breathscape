import 'package:flutter/material.dart';

class BreathingAnimationWidget extends StatelessWidget {
  const BreathingAnimationWidget({
    super.key,
    required this.fillLevel,
    required this.isAnimating,
    required this.circleScale,
    required this.circleOpacity,
    required this.circleBottomScale,
    required this.circleBottomOpacity,
  });

  final double fillLevel;
  final bool isAnimating;
  final double circleScale;
  final double circleOpacity;
  final double circleBottomScale;
  final double circleBottomOpacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircle(circleScale, circleOpacity),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Container(color: const Color(0xFF0D1520)),
                ),
                Flexible(
                  flex: 6,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFF1A2A3A)),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fillLevel.clamp(0.0, 1.0),
                          child: Container(color: const Color(0xFF4A9EBF)),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Container(color: const Color(0xFF0D1520)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCircle(circleBottomScale, circleBottomOpacity),
      ],
    );
  }

  Widget _buildCircle(double scale, double opacity) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A2A3A),
            ),
          ),
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4A9EBF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
