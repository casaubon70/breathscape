import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart'
    show BreathingState;
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:breathscape/features/breathing_session/presentation/pattern_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatternSelectorButton extends StatelessWidget {
  const PatternSelectorButton({required this.programs, super.key});

  final List<SessionProgram> programs;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;

    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (prev, curr) => prev.selectedProgram != curr.selectedProgram,
      builder: (context, state) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.l,
              spacing.m,
              spacing.l,
              spacing.s,
            ),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<SessionProgram>(
                  MaterialPageRoute<SessionProgram>(
                    builder: (_) => PatternPickerPage(
                      programs: programs,
                      selectedProgram: state.selectedProgram,
                    ),
                  ),
                );
                if (result != null && context.mounted) {
                  context.read<BreathingBloc>().add(ProgramSelected(result));
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.selectedProgram.name,
                    style: typography.dropdownItem,
                  ),
                  SizedBox(width: spacing.xs),
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: colors.iconSubtle,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
