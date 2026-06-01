import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/presentation/widgets/voice_mute_button.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/session_program.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_counter.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_dot_row.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/pattern_dropdown.dart'
    show PatternSelectorButton;
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/session_countdown.dart';
import 'package:breathscape/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BreathingSessionPage extends StatelessWidget {
  const BreathingSessionPage({super.key, this.programsLoader});

  final Future<List<SessionProgram>> Function()? programsLoader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PatternsBloc>(
      create: (_) =>
          PatternsBloc(programsLoader: programsLoader)
            ..add(const PatternsLoaded()),
      child: BlocBuilder<PatternsBloc, PatternsState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, state) {
          if (state.status != PatternsStatus.ready) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: context.bTheme.colors.textHint,
                ),
              ),
            );
          }
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => BreathingBloc(program: state.programs.first),
              ),
              BlocProvider(create: (_) => AudioBloc()),
            ],
            child: const _BreathingSessionView(),
          );
        },
      ),
    );
  }
}

class _BreathingSessionView extends StatelessWidget {
  const _BreathingSessionView();

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final programs = context.watch<PatternsBloc>().state.programs;

    return BlocListener<BreathingBloc, BreathingState>(
      listenWhen: (prev, curr) =>
          prev.currentPhase != curr.currentPhase || prev.status != curr.status,
      listener: (context, state) {
        final audioBloc = context.read<AudioBloc>();
        if (state.status == SessionStatus.playing) {
          audioBloc
            ..add(PlayPhaseVoiceCue(state.currentPhase))
            ..add(PlayPhaseNoiseCue(state.currentPhase));
        } else {
          audioBloc
            ..add(const StopVoiceCue())
            ..add(const StopNoiseCue());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  PatternSelectorButton(programs: programs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        spacing.m,
                        spacing.l,
                        spacing.s,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.gear,
                          color: colors.iconSubtle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dotsAreaHeight = CycleDotRow.totalHeight + spacing.m;
                    final animHeight =
                        ((constraints.maxHeight - dotsAreaHeight) * 0.40).clamp(
                          130.0,
                          300.0,
                        );
                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSessionArea(
                              context,
                              constraints,
                              animHeight,
                            ),
                          ),
                        ),
                        BlocBuilder<BreathingBloc, BreathingState>(
                          buildWhen: (prev, curr) =>
                              prev.currentCycle != curr.currentCycle ||
                              prev.selectedProgram != curr.selectedProgram ||
                              prev.extendedExhaleCycles !=
                                  curr.extendedExhaleCycles ||
                              prev.extendedInhaleCycles !=
                                  curr.extendedInhaleCycles,
                          builder: (context, dotState) => Padding(
                            padding: EdgeInsets.only(bottom: spacing.m),
                            child: CycleDotRow(
                              segments:
                                  dotState.selectedProgram.segments,
                              currentCycle: dotState.currentCycle,
                              extendedExhaleCycles:
                                  dotState.extendedExhaleCycles,
                              extendedInhaleCycles:
                                  dotState.extendedInhaleCycles,
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
                              prev.totalCycles != curr.totalCycles,
                          builder: (context, state) => CycleCounter(
                            current: state.currentCycle,
                            total: state.totalCycles,
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
      ),
    );
  }

  static bool _isAnimChange(BreathingState prev, BreathingState curr) =>
      prev.fillLevel != curr.fillLevel ||
      prev.circleScale != curr.circleScale ||
      prev.circleOpacity != curr.circleOpacity ||
      prev.circleBottomScale != curr.circleBottomScale ||
      prev.circleBottomOpacity != curr.circleBottomOpacity ||
      prev.currentPhase != curr.currentPhase ||
      prev.deepZoneFill != curr.deepZoneFill ||
      prev.topZoneFill != curr.topZoneFill ||
      prev.status != curr.status ||
      prev.showTopCircle != curr.showTopCircle ||
      prev.showBottomCircle != curr.showBottomCircle;

  static Widget _buildAnimWidget(
    BreathingState state,
    double animHeight,
    double animWidth,
  ) {
    return SizedBox(
      width: animWidth,
      child: BreathingAnimationWidget(
        height: animHeight,
        fillLevel: state.fillLevel,
        isAnimating: state.status == SessionStatus.playing,
        circleScale: state.circleScale,
        circleOpacity: state.circleOpacity,
        circleBottomScale: state.circleBottomScale,
        circleBottomOpacity: state.circleBottomOpacity,
        isExtendedExhale: state.isExtendedExhale,
        deepZoneFill: state.deepZoneFill,
        isExtendedInhale: state.isExtendedInhale,
        topZoneFill: state.topZoneFill,
        showTopCircle: state.showTopCircle,
        showBottomCircle: state.showBottomCircle,
      ),
    );
  }

  Widget _buildSessionArea(
    BuildContext context,
    BoxConstraints constraints,
    double animHeight,
  ) {
    final spacing = context.bTheme.spacing;
    final typography = context.bTheme.typography;
    final animWidth = animHeight * BreathingAnimationWidget.kCircleRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<BreathingBloc, BreathingState>(
          buildWhen: (prev, curr) =>
              prev.phaseSecondsRemaining != curr.phaseSecondsRemaining ||
              prev.currentPhase != curr.currentPhase ||
              prev.status != curr.status,
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _phaseLabel(state.status, state.currentPhase),
                style: typography.phaseLabel,
              ),
              SizedBox(height: spacing.s),
              Text(
                '${state.phaseSecondsRemaining}s',
                style: typography.countdown,
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.l),
        SizedBox(
          width: constraints.maxWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BlocBuilder<BreathingBloc, BreathingState>(
                buildWhen: _isAnimChange,
                builder: (context, state) =>
                    _buildAnimWidget(state, animHeight, animWidth),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: (constraints.maxWidth - animWidth) / 2,
                  child: const Center(child: VoiceMuteButton()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _phaseLabel(SessionStatus status, PhaseType phase) {
    if (status == SessionStatus.completed) return 'COMPLETE';
    if (status == SessionStatus.idle || status == SessionStatus.paused) {
      return 'READY';
    }
    return switch (phase) {
      PhaseType.inhale => 'INHALE',
      PhaseType.extendedInhale => 'DEEP INHALE',
      PhaseType.holdIn => 'HOLD',
      PhaseType.exhale => 'EXHALE',
      PhaseType.extendedExhale => 'DEEP EXHALE',
      PhaseType.holdOut => 'HOLD',
    };
  }
}
