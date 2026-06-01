import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PatternPickerPage extends StatelessWidget {
  const PatternPickerPage({
    required this.programs,
    required this.selectedProgram,
    super.key,
  });

  final List<SessionProgram> programs;
  final SessionProgram selectedProgram;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.iconSubtle),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.patternPickerTitle,
          style: TextStyle(
            color: colors.textHint,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: spacing.m),
        itemCount: programs.length,
        separatorBuilder: (_, __) => Divider(
          color: colors.surfaceDim,
          height: 1,
          indent: spacing.l,
          endIndent: spacing.l,
        ),
        itemBuilder: (context, index) {
          final program = programs[index];
          final isSelected = program == selectedProgram;
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.l,
              vertical: spacing.s,
            ),
            title: Text(
              program.name,
              style: typography.dropdownItem.copyWith(
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check, color: colors.accent, size: 18)
                : null,
            onTap: () => Navigator.of(context).pop(program),
          );
        },
      ),
    );
  }
}
