import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart'
    show
        BreathingPhase,
        PhaseType,
        kMaxPhaseDurationSeconds,
        kMinPhaseDurationSeconds;
import 'package:flutter/material.dart';

/// A single phase label + stepper. Leaf widget — no Bloc access.
///
/// [stacked] = true: label above stepper (for the aligned edit panel).
/// [stacked] = false (default): label left, stepper right (for lists).
class PhaseAdjusterRow extends StatelessWidget {
  const PhaseAdjusterRow({
    required this.phaseType,
    required this.seconds,
    required this.onDecrease,
    required this.onIncrease,
    this.canDecrease = true,
    this.canIncrease = true,
    this.stacked = false,
    super.key,
  });

  final PhaseType phaseType;
  final int seconds;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool canDecrease;
  final bool canIncrease;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final typography = context.bTheme.typography;
    final label = Text(
      _label(),
      style: typography.dropdownItem.copyWith(color: colors.textSecondary),
    );
    final stepper = _Stepper(
      seconds: seconds,
      canDecrease: canDecrease,
      canIncrease: canIncrease,
      onDecrease: onDecrease,
      onIncrease: onIncrease,
    );
    if (stacked) {
      return Column(mainAxisSize: MainAxisSize.min, children: [label, stepper]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, stepper],
    );
  }

  static String labelForType(PhaseType type) => switch (type) {
    PhaseType.inhale => 'INHALE',
    PhaseType.extendedInhale => 'DEEP INHALE',
    PhaseType.holdIn => 'HOLD',
    PhaseType.exhale => 'EXHALE',
    PhaseType.extendedExhale => 'DEEP EXHALE',
    PhaseType.holdOut => 'HOLD',
  };

  String _label() => labelForType(phaseType);
}

/// Edit-mode control that lists every base phase of a pattern with a stepper
/// to increase/decrease its duration in seconds.
///
/// Leaf widget — receives primitive data and callbacks only, no Bloc access.
class PhaseAdjuster extends StatelessWidget {
  const PhaseAdjuster({
    required this.phases,
    required this.onChanged,
    this.onReset,
    this.minSeconds = kMinPhaseDurationSeconds,
    this.maxSeconds = kMaxPhaseDurationSeconds,
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
    final spacing = context.bTheme.spacing;
    final colors = context.bTheme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < phases.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.xs),
            child: PhaseAdjusterRow(
              phaseType: phases[i].type,
              seconds: phases[i].duration.inSeconds,
              canDecrease: phases[i].duration.inSeconds > minSeconds,
              canIncrease: phases[i].duration.inSeconds < maxSeconds,
              onDecrease: () => onChanged(i, phases[i].duration.inSeconds - 1),
              onIncrease: () => onChanged(i, phases[i].duration.inSeconds + 1),
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
