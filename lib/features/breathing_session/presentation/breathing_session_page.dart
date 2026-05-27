import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/presentation/patterns/patterns_data.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';

class BreathingSessionPage extends StatelessWidget {
  const BreathingSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BreathingBloc(pattern: PatternsData.boxBreathing),
      child: const _BreathingSessionView(),
    );
  }
}

class _BreathingSessionView extends StatelessWidget {
  const _BreathingSessionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: BlocBuilder<BreathingBloc, BreathingState>(
                        builder: (context, state) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                        Text(
                          _phaseLabel(state.currentPhase),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cycle ${state.currentCycle}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 120,
                          child: BreathingAnimationWidget(
                            fillLevel: state.fillLevel,
                            isAnimating: state.status == SessionStatus.playing,
                            circleScale: state.circleScale,
                            circleOpacity: state.circleOpacity,
                            circleBottomScale: state.circleBottomScale,
                            circleBottomOpacity: state.circleBottomOpacity,
                          ),
                        ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            BlocBuilder<BreathingBloc, BreathingState>(
              buildWhen: (prev, curr) => prev.status != curr.status,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: PlaybackControls(
                    status: state.status,
                    onPlay: () =>
                        context.read<BreathingBloc>().add(PlayPressed()),
                    onPause: () =>
                        context.read<BreathingBloc>().add(PausePressed()),
                    onReset: () =>
                        context.read<BreathingBloc>().add(ResetPressed()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(PhaseType phase) {
    return switch (phase) {
      PhaseType.inhale => 'INHALE',
      PhaseType.holdIn => 'HOLD',
      PhaseType.exhale => 'EXHALE',
      PhaseType.holdOut => 'HOLD',
    };
  }
}
