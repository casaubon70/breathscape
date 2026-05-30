import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:flutter/material.dart';

/// Edit-mode control that lists every base phase of a pattern with a stepper
/// to increase/decrease its duration in seconds.
///
/// Leaf widget — receives primitive data and callbacks only, no Bloc access.
class PhaseAdjuster extends StatelessWidget {
  const PhaseAdjuster({
    required this.phases,
    required this.onChanged,
    this.onReset,
    this.minSeconds = 1,
    this.maxSeconds = 99,
    super.key,
  });

  final List<BreathingPhase> phases;

  /// Called with the phase index and the new desired duration in seconds.
  final void Function(int phaseIndex, int seconds) onChanged;

  /// Called when the user resets the pattern to its bundled defaults.
  final VoidCallback? onReset;

  final int minSeconds;
  final int maxSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < phases.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _phaseLabel(phases[i].type),
                  style: typography.dropdownItem.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                _Stepper(
                  seconds: phases[i].duration.inSeconds,
                  canDecrease: phases[i].duration.inSeconds > minSeconds,
                  canIncrease: phases[i].duration.inSeconds < maxSeconds,
                  onDecrease: () =>
                      onChanged(i, phases[i].duration.inSeconds - 1),
                  onIncrease: () =>
                      onChanged(i, phases[i].duration.inSeconds + 1),
                ),
              ],
            ),
          ),
        if (onReset != null) ...[
          SizedBox(height: spacing.m),
          TextButton(
            onPressed: onReset,
            child: Text(
              'AUF STANDARD ZURÜCKSETZEN',
              style: TextStyle(
                color: colors.textHint,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _phaseLabel(PhaseType type) => switch (type) {
    PhaseType.inhale => 'INHALE',
    PhaseType.holdIn => 'HOLD',
    PhaseType.exhale => 'EXHALE',
    PhaseType.extendedExhale => 'DEEP EXHALE',
    PhaseType.holdOut => 'HOLD',
  };
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.seconds,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int seconds;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final typography = context.bTheme.typography;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 22,
          color: colors.signal,
          disabledColor: colors.surfaceDim,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: canDecrease ? onDecrease : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${seconds}s',
            textAlign: TextAlign.center,
            style: typography.dropdownItem,
          ),
        ),
        IconButton(
          iconSize: 22,
          color: colors.signal,
          disabledColor: colors.surfaceDim,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: canIncrease ? onIncrease : null,
        ),
      ],
    );
  }
}
