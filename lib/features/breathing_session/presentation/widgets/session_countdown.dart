import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SessionCountdown extends StatelessWidget {
  const SessionCountdown({required this.seconds, super.key});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
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
          AppLocalizations.of(context)!.sessionTimerLabel,
          style: labelStyle,
        ),
        Text(
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}',
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
