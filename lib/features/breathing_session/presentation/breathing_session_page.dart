import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/patterns_repository.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/pattern_dropdown.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BreathingSessionPage extends StatefulWidget {
  const BreathingSessionPage({super.key, this.patternsLoader});

  final Future<List<BreathingPattern>> Function()? patternsLoader;

  @override
  State<BreathingSessionPage> createState() => _BreathingSessionPageState();
}

class _BreathingSessionPageState extends State<BreathingSessionPage> {
  late final Future<List<BreathingPattern>> _patternsFuture;

  @override
  void initState() {
    super.initState();
    _patternsFuture = (widget.patternsLoader ?? PatternsRepository.load)();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BreathingPattern>>(
      future: _patternsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white38),
            ),
          );
        }
        final patterns = snapshot.data!;
        return BlocProvider(
          create: (_) => BreathingBloc(pattern: patterns.first),
          child: _BreathingSessionView(patterns: patterns),
        );
      },
    );
  }
}

class _BreathingSessionView extends StatelessWidget {
  const _BreathingSessionView({required this.patterns});

  final List<BreathingPattern> patterns;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            PatternDropdown(patterns: patterns),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                                '${state.phaseSecondsRemaining}s',
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
                                  isAnimating:
                                      state.status == SessionStatus.playing,
                                  circleScale: state.circleScale,
                                  circleOpacity: state.circleOpacity,
                                  circleBottomScale: state.circleBottomScale,
                                  circleBottomOpacity:
                                      state.circleBottomOpacity,
                                  showTopCircle: state.selectedPattern.phases
                                      .any((p) => p.type == PhaseType.holdIn),
                                  showBottomCircle: state.selectedPattern.phases
                                      .any((p) => p.type == PhaseType.holdOut),
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
                        context.read<BreathingBloc>().add(const PlayPressed()),
                    onPause: () =>
                        context.read<BreathingBloc>().add(const PausePressed()),
                    onReset: () =>
                        context.read<BreathingBloc>().add(const ResetPressed()),
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
