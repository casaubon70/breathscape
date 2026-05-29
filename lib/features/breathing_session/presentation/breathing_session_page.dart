import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/patterns_repository.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_counter.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_dot_row.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/pattern_dropdown.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/session_countdown.dart';
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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: context.bTheme.colors.textHint,
              ),
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
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PatternDropdown(patterns: patterns),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 0.40 accounts for circles (each 37.5% of bar height)
                  // and labels above. Total widget H ≈ barH × 1.75 + 32 px.
                  // Subtract the dot-row area derived from the widget's own
                  // constant + the theme spacing so no magic number creeps in.
                  final dotsAreaHeight = CycleDotRow.dotLarge + spacing.m;
                  final animHeight =
                      ((constraints.maxHeight - dotsAreaHeight) * 0.40).clamp(
                        130.0,
                        300.0,
                      );
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: BlocBuilder<BreathingBloc, BreathingState>(
                            builder: (context, state) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _phaseLabel(
                                      state.status,
                                      state.currentPhase,
                                    ),
                                    style: typography.phaseLabel,
                                  ),
                                  SizedBox(height: spacing.s),
                                  Text(
                                    '${state.phaseSecondsRemaining}s',
                                    style: typography.countdown,
                                  ),
                                  SizedBox(height: spacing.l),
                                  SizedBox(
                                    width: animHeight * 0.375,
                                    child: BreathingAnimationWidget(
                                      height: animHeight,
                                      fillLevel: state.fillLevel,
                                      isAnimating:
                                          state.status == SessionStatus.playing,
                                      circleScale: state.circleScale,
                                      circleOpacity: state.circleOpacity,
                                      circleBottomScale:
                                          state.circleBottomScale,
                                      circleBottomOpacity:
                                          state.circleBottomOpacity,
                                      isExtendedExhale: state.isExtendedExhale,
                                      deepZoneFill: state.deepZoneFill,
                                      showTopCircle: state
                                          .selectedPattern
                                          .phases
                                          .any(
                                            (p) => p.type == PhaseType.holdIn,
                                          ),
                                      showBottomCircle: state
                                          .selectedPattern
                                          .phases
                                          .any(
                                            (p) => p.type == PhaseType.holdOut,
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      BlocBuilder<BreathingBloc, BreathingState>(
                        buildWhen: (prev, curr) =>
                            prev.currentCycle != curr.currentCycle ||
                            prev.selectedPattern != curr.selectedPattern,
                        builder: (context, dotState) => Padding(
                          padding: EdgeInsets.only(bottom: spacing.m),
                          child: CycleDotRow(
                            totalCycles: dotState.selectedPattern.defaultCycles,
                            currentCycle: dotState.currentCycle,
                            extendedExhaleInterval:
                                dotState.selectedPattern.extendedExhaleInterval,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: spacing.xl,
                left: spacing.m,
                right: spacing.m,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BlocBuilder<BreathingBloc, BreathingState>(
                    buildWhen: (prev, curr) => prev.status != curr.status,
                    builder: (context, state) => PlaybackControls(
                      status: state.status,
                      onPlay: () => context.read<BreathingBloc>().add(
                        const PlayPressed(),
                      ),
                      onPause: () => context.read<BreathingBloc>().add(
                        const PausePressed(),
                      ),
                      onReset: () => context.read<BreathingBloc>().add(
                        const ResetPressed(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: spacing.m),
                      child: BlocBuilder<BreathingBloc, BreathingState>(
                        buildWhen: (prev, curr) =>
                            prev.sessionSecondsRemaining !=
                            curr.sessionSecondsRemaining,
                        builder: (context, state) => SessionCountdown(
                          seconds: state.sessionSecondsRemaining,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: spacing.m),
                      child: BlocBuilder<BreathingBloc, BreathingState>(
                        buildWhen: (prev, curr) =>
                            prev.currentCycle != curr.currentCycle ||
                            prev.selectedPattern != curr.selectedPattern,
                        builder: (context, state) => CycleCounter(
                          current: state.currentCycle,
                          total: state.selectedPattern.defaultCycles,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(SessionStatus status, PhaseType phase) {
    if (status == SessionStatus.completed) return 'COMPLETE';
    if (status == SessionStatus.idle || status == SessionStatus.paused) {
      return 'READY';
    }
    return switch (phase) {
      PhaseType.inhale => 'INHALE',
      PhaseType.holdIn => 'HOLD',
      PhaseType.exhale => 'EXHALE',
      PhaseType.extendedExhale => 'DEEP EXHALE',
      PhaseType.holdOut => 'HOLD',
    };
  }
}
