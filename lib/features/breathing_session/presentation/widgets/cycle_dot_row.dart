import 'package:breathscape/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CycleDotRow extends StatelessWidget {
  const CycleDotRow({
    required this.totalCycles,
    required this.currentCycle,
    this.extendedExhaleInterval,
    this.extendedInhaleInterval,
    super.key,
  });

  final int totalCycles;
  final int currentCycle;
  final int? extendedExhaleInterval;
  final int? extendedInhaleInterval;

  static const double _dotSmall = 6;

  /// Public so callers can reserve exact space without a magic number.
  static const double dotLarge = 10;
  static const double _arrowLarge = 20;
  static const double _arrowSmall = 12;
  static const double _gap = 5;

  /// The height of a row item. Arrows are taller than dots, so callers must
  /// reserve this height rather than [dotLarge].
  static const double rowHeight = _arrowLarge;

  bool _isDeepExhaleCycle(int cycle) {
    final interval = extendedExhaleInterval;
    return interval != null && interval > 0 && cycle % interval == 0;
  }

  bool _isDeepInhaleCycle(int cycle) {
    final interval = extendedInhaleInterval;
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
        final isDeepExhale = _isDeepExhaleCycle(cycle);
        final isDeepInhale = _isDeepInhaleCycle(cycle);
        final isDeep = isDeepExhale || isDeepInhale;

        final baseColor = isDeep ? colors.signal : colors.accent;
        final color = isCurrent ? baseColor : baseColor.withValues(alpha: 0.35);

        if (isDeepInhale && isDeepExhale) {
          return SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.arrowsUpDown,
                size: isCurrent ? _arrowLarge : _arrowSmall,
                color: color,
              ),
            ),
          );
        }

        if (isDeepInhale) {
          return SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.arrowUp,
                size: isCurrent ? _arrowLarge : _arrowSmall,
                color: color,
              ),
            ),
          );
        }

        if (isDeepExhale) {
          return SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.arrowDown,
                size: isCurrent ? _arrowLarge : _arrowSmall,
                color: color,
              ),
            ),
          );
        }

        final dotSize = isCurrent ? dotLarge : _dotSmall;
        return SizedBox(
          width: rowHeight,
          height: rowHeight,
          child: Center(
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        );
      }),
    );
  }
}
