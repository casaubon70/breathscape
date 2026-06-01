import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CycleDotRow extends StatelessWidget {
  const CycleDotRow({
    required this.segments,
    required this.currentCycle,
    this.extendedExhaleCycles = const <int>{},
    this.extendedInhaleCycles = const <int>{},
    super.key,
  });

  final List<SessionSegment> segments;
  final int currentCycle;

  /// 1-based cycle indices that should display a deep-exhale arrow.
  final Set<int> extendedExhaleCycles;

  /// 1-based cycle indices that should display a deep-inhale arrow.
  final Set<int> extendedInhaleCycles;

  static const double _dotSmall = 6;

  /// Public so callers can reserve exact space without a magic number.
  static const double dotLarge = 10;
  static const double _arrowLarge = 20;
  static const double _arrowSmall = 12;
  static const double _gap = 5;

  /// The height of the dots row. Arrows are taller than dots.
  static const double rowHeight = _arrowLarge;

  static const double _labelFontSize = 9;
  static const double _labelLineHeight = 13;
  static const double _labelGap = 4;

  /// Total height of one segment column (label + gap + dots).
  static const double totalHeight = _labelLineHeight + _labelGap + rowHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    var absoluteCycle = 1;
    final children = <Widget>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final segmentStart = absoluteCycle;

      final dots = List.generate(segment.cycleCount, (j) {
        return _buildDot(segmentStart + j, colors);
      });

      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              segment.label.toUpperCase(),
              style: TextStyle(
                color: colors.textHint,
                fontSize: _labelFontSize,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                height: _labelLineHeight / _labelFontSize,
              ),
            ),
            const SizedBox(height: _labelGap),
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: dots,
            ),
          ],
        ),
      );

      if (i < segments.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 1,
              height: totalHeight,
              child: ColoredBox(color: colors.textHint.withValues(alpha: 0.3)),
            ),
          ),
        );
      }

      absoluteCycle += segment.cycleCount;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildDot(int cycle, BreathscapeColors colors) {
    final isCurrent = cycle == currentCycle;
    final isDeepExhale = extendedExhaleCycles.contains(cycle);
    final isDeepInhale = extendedInhaleCycles.contains(cycle);
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
  }
}
