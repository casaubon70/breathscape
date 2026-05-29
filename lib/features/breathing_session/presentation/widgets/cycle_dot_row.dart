import 'package:breathscape/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CycleDotRow extends StatelessWidget {
  const CycleDotRow({
    required this.totalCycles,
    required this.currentCycle,
    this.extendedExhaleInterval,
    super.key,
  });

  final int totalCycles;
  final int currentCycle;
  final int? extendedExhaleInterval;

  static const double _dotSmall = 6;

  /// Public so callers can reserve exact space without a magic number.
  static const double dotLarge = 10;
  static const double _gap = 5;

  bool _isDeepCycle(int cycle) {
    final interval = extendedExhaleInterval;
    return interval != null && interval > 0 && cycle % interval == 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(totalCycles, (index) {
        final cycle = index + 1;
        final isCurrent = cycle == currentCycle;
        final isDeep = _isDeepCycle(cycle);

        final baseColor = isDeep ? colors.signal : colors.accent;
        final color = isCurrent ? baseColor : baseColor.withValues(alpha: 0.35);
        final size = isCurrent ? dotLarge : _dotSmall;

        return SizedBox(
          width: dotLarge,
          height: dotLarge,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        );
      }),
    );
  }
}
