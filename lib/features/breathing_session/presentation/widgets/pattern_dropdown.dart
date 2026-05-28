import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart'
    show BreathingState;
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatternDropdown extends StatelessWidget {
  const PatternDropdown({required this.patterns, super.key});

  final List<BreathingPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;

    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (prev, curr) => prev.selectedPattern != curr.selectedPattern,
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
            child: DropdownButton<BreathingPattern>(
              value: state.selectedPattern,
              dropdownColor: colors.surfaceDropdown,
              underline: const SizedBox.shrink(),
              icon: Icon(Icons.keyboard_arrow_down, color: colors.iconSubtle),
              style: typography.dropdownItem,
              items: patterns
                  .map(
                    (p) => DropdownMenuItem<BreathingPattern>(
                      value: p,
                      child: Text(p.name),
                    ),
                  )
                  .toList(),
              onChanged: (pattern) {
                if (pattern != null) {
                  context.read<BreathingBloc>().add(PatternSelected(pattern));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
