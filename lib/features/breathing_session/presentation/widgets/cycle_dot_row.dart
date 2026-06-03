import 'dart:math';

import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_colors.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CycleDotRow extends StatefulWidget {
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

  /// Padding(h:8) + ColoredBox(w:1) = 17.
  static const double _dividerWidth = 17;

  /// Minimum horizontal margin from screen edges in single-segment view.
  static const double _edgeMargin = 16;

  static const double _paginatorGap = 12;
  static const double _paginatorDashWidth = 16;
  static const double _paginatorDashHeight = 3;
  static const double _paginatorDotGap = 5;
  static const double _paginatorTapHeight = 36;

  /// The height of the dots row. Arrows are taller than dots.
  static const double rowHeight = _arrowLarge;

  static const double _labelFontSize = 9;
  static const double _labelLineHeight = 13;
  static const double _labelGap = 4;

  /// Height of the dot row (label + gap + dots).
  static const double totalHeight = _labelLineHeight + _labelGap + rowHeight;

  /// Extra height added when the paginator is visible (gap + tap-target).
  /// Callers that pre-calculate layout space should add this to [totalHeight]
  /// as a conservative upper bound.
  static const double paginatorHeight = _paginatorGap + _paginatorTapHeight;

  @override
  State<CycleDotRow> createState() => _CycleDotRowState();
}

class _CycleDotRowState extends State<CycleDotRow> {
  int _visibleStart = 0;

  // Cached from the last build(); used in didUpdateWidget() to decide whether
  // auto-navigation is needed. Conservative default: assume all visible so
  // that no premature navigation fires before the first build.
  bool _allFitCached = true;

  @override
  void didUpdateWidget(CycleDotRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visibleStart >= widget.segments.length) {
      setState(() => _visibleStart = 0);
      return;
    }
    if (oldWidget.currentCycle != widget.currentCycle && !_allFitCached) {
      final segIdx = _segmentForCycle(widget.currentCycle);
      if (segIdx != _visibleStart) {
        setState(() => _visibleStart = segIdx);
      }
    }
  }

  int _segmentForCycle(int cycle) {
    var start = 1;
    for (var i = 0; i < widget.segments.length; i++) {
      if (cycle < start + widget.segments[i].cycleCount) return i;
      start += widget.segments[i].cycleCount;
    }
    return widget.segments.length - 1;
  }

  double _segmentWidth(SessionSegment s) {
    final painter = TextPainter(
      text: TextSpan(
        text: s.label.toUpperCase(),
        style: const TextStyle(
          fontSize: CycleDotRow._labelFontSize,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dotsWidth =
        s.cycleCount * (CycleDotRow.rowHeight + CycleDotRow._gap) -
        CycleDotRow._gap;
    return max(dotsWidth, painter.width);
  }

  int _countFitting(double budget, int start) {
    var used = 0.0;
    var count = 0;
    for (var i = start; i < widget.segments.length; i++) {
      final divider = count > 0 ? CycleDotRow._dividerWidth : 0.0;
      final w = _segmentWidth(widget.segments[i]) + divider;
      if (used + w <= budget) {
        used += w;
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final allFit = _countFitting(available, 0) >= widget.segments.length;
        final showPaginator = !allFit;

        // All segments fit → show all from 0.
        // Overflow → show exactly 1 segment (the one at _visibleStart).
        _allFitCached = allFit;
        final start = allFit ? 0 : _visibleStart;
        final visibleCount = allFit ? widget.segments.length : 1;

        // In single-segment view subtract edge margins so dots don't touch
        // the screen border and the spacing calculation stays accurate.
        final effectiveWidth = allFit
            ? available
            : available - 2 * CycleDotRow._edgeMargin;

        var absoluteCycle =
            1 +
            widget.segments
                .take(start)
                .fold<int>(0, (sum, s) => sum + s.cycleCount);

        final rowChildren = <Widget>[];
        for (var i = start; i < start + visibleCount; i++) {
          if (i > start) rowChildren.add(_buildDivider(colors));

          final segment = widget.segments[i];
          final segStart = absoluteCycle;

          // Reduce spacing so dots fit in one row when possible. The
          // ConstrainedBox gives Wrap a bounded maxWidth so it wraps
          // correctly instead of laying all dots on an infinite line.
          final n = segment.cycleCount;
          final adaptiveSpacing = n <= 1
              ? CycleDotRow._gap
              : ((effectiveWidth - n * CycleDotRow.rowHeight) / (n - 1)).clamp(
                  0.0,
                  CycleDotRow._gap,
                );

          rowChildren.add(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveWidth),
              child: Column(
                crossAxisAlignment: allFit
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    segment.label.toUpperCase(),
                    style: TextStyle(
                      color: colors.textHint,
                      fontSize: CycleDotRow._labelFontSize,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      height:
                          CycleDotRow._labelLineHeight /
                          CycleDotRow._labelFontSize,
                    ),
                  ),
                  const SizedBox(height: CycleDotRow._labelGap),
                  Wrap(
                    spacing: adaptiveSpacing,
                    runSpacing: CycleDotRow._gap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(
                      segment.cycleCount,
                      (j) => _buildDot(segStart + j, colors),
                    ),
                  ),
                ],
              ),
            ),
          );

          absoluteCycle += segment.cycleCount;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
            if (showPaginator) ...[
              const SizedBox(height: CycleDotRow._paginatorGap),
              _buildPaginator(visibleCount, colors),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPaginator(int visibleCount, BreathscapeColors colors) {
    final activeSegIdx = _segmentForCycle(widget.currentCycle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.segments.length, (i) {
        final isVisible =
            i >= _visibleStart && i < _visibleStart + visibleCount;
        return _PaginatorDash(
          key: Key('cycle_dot_page_$i'),
          isVisible: isVisible,
          isActive: i == activeSegIdx,
          hasRightGap: i < widget.segments.length - 1,
          onTap: () => setState(() => _visibleStart = i),
          colors: colors,
        );
      }),
    );
  }

  Widget _buildDivider(BreathscapeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 1,
        height: CycleDotRow.totalHeight,
        child: ColoredBox(color: colors.textHint.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildDot(int cycle, BreathscapeColors colors) {
    final isCurrent = cycle == widget.currentCycle;
    final isDeepExhale = widget.extendedExhaleCycles.contains(cycle);
    final isDeepInhale = widget.extendedInhaleCycles.contains(cycle);
    final isDeep = isDeepExhale || isDeepInhale;

    final baseColor = isDeep ? colors.signal : colors.accent;
    final color = isCurrent ? baseColor : baseColor.withValues(alpha: 0.35);
    final iconSize = isCurrent
        ? CycleDotRow._arrowLarge
        : CycleDotRow._arrowSmall;

    if (isDeepInhale && isDeepExhale) {
      return _iconDot(FontAwesomeIcons.arrowsUpDown, iconSize, color);
    }
    if (isDeepInhale) {
      return _iconDot(FontAwesomeIcons.arrowUp, iconSize, color);
    }
    if (isDeepExhale) {
      return _iconDot(FontAwesomeIcons.arrowDown, iconSize, color);
    }

    final dotSize = isCurrent ? CycleDotRow.dotLarge : CycleDotRow._dotSmall;
    return SizedBox(
      width: CycleDotRow.rowHeight,
      height: CycleDotRow.rowHeight,
      child: Center(
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }

  Widget _iconDot(FaIconData icon, double size, Color color) => SizedBox(
    width: CycleDotRow.rowHeight,
    height: CycleDotRow.rowHeight,
    child: Center(
      child: FaIcon(icon, size: size, color: color),
    ),
  );
}

// ---------------------------------------------------------------------------

class _PaginatorDash extends StatefulWidget {
  const _PaginatorDash({
    required this.isVisible,
    required this.isActive,
    required this.hasRightGap,
    required this.onTap,
    required this.colors,
    super.key,
  });

  final bool isVisible;

  /// True when this segment contains the currently active cycle.
  final bool isActive;
  final bool hasRightGap;
  final VoidCallback onTap;
  final BreathscapeColors colors;

  @override
  State<_PaginatorDash> createState() => _PaginatorDashState();
}

class _PaginatorDashState extends State<_PaginatorDash> {
  bool _hovered = false;

  // Active segment → signal color; all others → accent.
  Color get _color =>
      widget.isActive ? widget.colors.signal : widget.colors.accent;

  double get _alpha {
    if (widget.isActive || widget.isVisible) return 1;
    return _hovered ? 0.6 : 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || widget.isVisible;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(
            right: widget.hasRightGap ? CycleDotRow._paginatorDotGap : 0,
          ),
          child: SizedBox(
            width: CycleDotRow._paginatorDashWidth,
            height: CycleDotRow._paginatorTapHeight,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: CycleDotRow._paginatorDashWidth,
                height: _hovered && !highlighted
                    ? CycleDotRow._paginatorDashHeight + 1
                    : CycleDotRow._paginatorDashHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    CycleDotRow._paginatorDashHeight / 2,
                  ),
                  color: _color.withValues(alpha: _alpha),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
