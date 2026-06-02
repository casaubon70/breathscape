import 'package:breathscape/core/responsive/breakpoints.dart';
import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_spacing.dart';
import 'package:breathscape/features/disclaimer/bloc/disclaimer_bloc.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.bTheme.spacing;
    final isExpanded = Breakpoints.isExpanded(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isExpanded ? 600 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _DisclaimerBody(l10n: l10n, spacing: spacing),
                    ),
                  ),
                  SizedBox(height: spacing.m),
                  _AcceptButton(
                    label: l10n.disclaimerAcceptButton,
                    spacing: spacing,
                    onPressed: () => context.read<DisclaimerBloc>().add(
                      const DisclaimerAccepted(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerBody extends StatelessWidget {
  const _DisclaimerBody({required this.l10n, required this.spacing});

  final AppLocalizations l10n;
  final BreathscapeSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.disclaimerTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: spacing.l),
        Text(
          l10n.disclaimerIntro,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        SizedBox(height: spacing.l),
        ...[
          l10n.disclaimerBullet1,
          l10n.disclaimerBullet2,
          l10n.disclaimerBullet3,
          l10n.disclaimerBullet4,
        ].map(
          (text) => Padding(
            padding: EdgeInsets.only(bottom: spacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(color: colors.accent, fontSize: 15),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    required this.label,
    required this.spacing,
    required this.onPressed,
  });

  final String label;
  final BreathscapeSpacing spacing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.s),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }
}
