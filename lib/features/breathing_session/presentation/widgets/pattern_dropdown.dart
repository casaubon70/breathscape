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
    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (prev, curr) => prev.selectedPattern != curr.selectedPattern,
      builder: (context, state) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: DropdownButton<BreathingPattern>(
              value: state.selectedPattern,
              dropdownColor: const Color(0xFF1A2E42),
              underline: const SizedBox.shrink(),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
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
