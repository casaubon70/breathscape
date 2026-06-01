import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CycleCounter extends StatelessWidget {
  const CycleCounter({required this.current, required this.total, super.key});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final labelStyle = TextStyle(
      color: colors.signal,
      fontSize: 12,
      letterSpacing: 2,
      fontFeatures: const [FontFeature.enable('smcp')],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context)!.cycleCounterLabel,
          style: labelStyle,
        ),
        Text(
          '$current/$total',
          style: TextStyle(
            color: colors.signal,
            fontSize: 17,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
