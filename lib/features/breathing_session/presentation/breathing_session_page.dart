import 'package:breathscape/core/theme/app_theme.dart';
import 'package:breathscape/core/theme/data/app_spacing.dart';
import 'package:breathscape/features/audio/bloc/audio_bloc.dart';
import 'package:breathscape/features/audio/bloc/audio_event.dart';
import 'package:breathscape/features/audio/presentation/widgets/voice_mute_button.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_event.dart';
import 'package:breathscape/features/breathing_session/bloc/breathing_state.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_bloc.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_event.dart';
import 'package:breathscape/features/breathing_session/bloc/patterns_state.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_pattern.dart';
import 'package:breathscape/features/breathing_session/domain/breathing_phase.dart';
import 'package:breathscape/features/breathing_session/domain/pattern_overrides_repository.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_counter.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/cycle_dot_row.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/pattern_dropdown.dart'
    show PatternSelectorButton;
import 'package:breathscape/features/breathing_session/presentation/widgets/phase_adjuster.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/playback_controls.dart';
import 'package:breathscape/features/breathing_session/presentation/widgets/session_countdown.dart';
import 'package:breathscape/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BreathingSessionPage extends StatelessWidget {
  const BreathingSessionPage({super.key, this.patternsLoader});

  final Future<List<BreathingPattern>> Function()? patternsLoader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PatternsBloc>(
      create: (_) => PatternsBloc(
        overridesRepository: PatternOverridesRepository(),
        baseLoader: patternsLoader,
      )..add(const PatternsLoaded()),
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
                create: (_) => BreathingBloc(pattern: state.patterns.first),
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

class _BreathingSessionView extends StatefulWidget {
  const _BreathingSessionView();

  @override
  State<_BreathingSessionView> createState() => _BreathingSessionViewState();
}

class _BreathingSessionViewState extends State<_BreathingSessionView> {
  bool _editMode = false;

  void _toggleEdit() {
    setState(() => _editMode = !_editMode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bTheme.colors;
    final spacing = context.bTheme.spacing;
    final patterns = context.watch<PatternsBloc>().state.patterns;

    return MultiBlocListener(
      listeners: [
        BlocListener<BreathingBloc, BreathingState>(
          listenWhen: (prev, curr) =>
              prev.currentPhase != curr.currentPhase ||
              prev.status != curr.status,
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
        ),
        // Syncs edited durations into BreathingBloc without resetting session.
        BlocListener<PatternsBloc, PatternsState>(
          listenWhen: (prev, curr) => prev.patterns != curr.patterns,
          listener: (context, state) {
            final breathingBloc = context.read<BreathingBloc>();
            final selectedName = breathingBloc.state.selectedPattern.name;
            final updated = state.patterns.firstWhere(
              (p) => p.name == selectedName,
              orElse: () => state.patterns.first,
            );
            if (updated != breathingBloc.state.selectedPattern) {
              breathingBloc.add(PatternDurationUpdated(updated));
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  PatternSelectorButton(patterns: patterns),
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
                    // 0.40 accounts for circles (each 37.5% of bar height)
                    // and labels above. Total widget H ≈ barH × 1.75 + 32 px.
                    // Subtract the dot-row area derived from the widget's own
                    // constant + the theme spacing so no magic number
                    // creeps in.
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
                            child: _buildSessionArea(
                              context,
                              constraints,
                              animHeight,
                            ),
                          ),
                        ),
                        // Always reserve the dot-row space so animHeight
                        // stays stable when toggling edit mode.
                        Opacity(
                          opacity: _editMode ? 0.0 : 1.0,
                          child: BlocBuilder<BreathingBloc, BreathingState>(
                            buildWhen: (prev, curr) =>
                                prev.currentCycle != curr.currentCycle ||
                                prev.selectedPattern != curr.selectedPattern,
                            builder: (context, dotState) => Padding(
                              padding: EdgeInsets.only(bottom: spacing.m),
                              child: CycleDotRow(
                                totalCycles:
                                    dotState.selectedPattern.defaultCycles,
                                currentCycle: dotState.currentCycle,
                                extendedExhaleInterval: dotState
                                    .selectedPattern
                                    .extendedExhaleInterval,
                              ),
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
                        // Hidden in edit mode: a dedicated RESET button for
                        // pattern defaults is shown in the left slot instead.
                        onReset: _editMode
                            ? null
                            : () => context.read<BreathingBloc>().add(
                                const ResetPressed(),
                              ),
                        onSettings: _toggleEdit,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: spacing.m),
                        child: _editMode
                            ? TextButton(
                                onPressed: () =>
                                    context.read<PatternsBloc>().add(
                                  PatternReset(
                                    context
                                        .read<BreathingBloc>()
                                        .state
                                        .selectedPattern
                                        .name,
                                  ),
                                ),
                                child: Text(
                                  'RESET',
                                  style: TextStyle(
                                    color: colors.textHint,
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              )
                            : BlocBuilder<BreathingBloc, BreathingState>(
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

    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (prev, curr) =>
          prev.fillLevel != curr.fillLevel ||
          prev.phaseSecondsRemaining != curr.phaseSecondsRemaining ||
          prev.currentPhase != curr.currentPhase ||
          prev.status != curr.status ||
          prev.selectedPattern != curr.selectedPattern ||
          prev.circleScale != curr.circleScale ||
          prev.circleOpacity != curr.circleOpacity ||
          prev.circleBottomScale != curr.circleBottomScale ||
          prev.circleBottomOpacity != curr.circleBottomOpacity ||
          prev.isExtendedExhale != curr.isExtendedExhale ||
          prev.deepZoneFill != curr.deepZoneFill,
      builder: (context, state) {
        final showTopCircle = state.selectedPattern.phases.any(
          (p) => p.type == PhaseType.holdIn,
        );
        final showBottomCircle = state.selectedPattern.phases
            .any((p) => p.type == PhaseType.holdOut);
        final animWidget = SizedBox(
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
            showTopCircle: showTopCircle,
            showBottomCircle: showBottomCircle,
          ),
        );

        return Column(
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
            SizedBox(height: spacing.l),
            SizedBox(
              width: constraints.maxWidth,
              child: _editMode
                  ? _buildEditRow(
                      context, state, animWidget, animHeight,
                      constraints.maxWidth, spacing,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        animWidget,
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
      },
    );
  }

  /// Edit layout: animation centered, per-phase adjusters (label above stepper)
  /// on the right, each aligned to its corresponding visual element.
  Widget _buildEditRow(
    BuildContext context,
    BreathingState state,
    Widget animWidget,
    double animHeight,
    double maxWidth,
    BreathscapeSpacing spacing,
  ) {
    // Animation column geometry — uses BreathingAnimationWidget constants as
    // the single source of truth so layout stays in sync if they ever change.
    final circleSize = animHeight * BreathingAnimationWidget.kCircleRatio;
    const barGap = BreathingAnimationWidget.kBarGap;
    final barTop = circleSize + barGap;
    final totalHeight = circleSize * 2 + barGap * 2 + animHeight;

    // Center-Y for each phase type, from the top of the animation widget.
    double centerY(PhaseType type) => switch (type) {
      PhaseType.holdIn => circleSize * 0.5,
      PhaseType.inhale => barTop + animHeight * 0.3,
      PhaseType.exhale => barTop + animHeight * 0.7,
      PhaseType.holdOut =>
        barTop + animHeight + barGap + circleSize * 0.5,
      PhaseType.extendedExhale => barTop + animHeight * 0.7,
    };

    // Stacked label (~16 px) + stepper (~30 px) = ~46 px total.
    const rowHalfHeight = 23.0;

    // Left edge of the adjuster area: right of centered animation.
    // Clamped so right: spacing.m never yields a negative Positioned width.
    final adjustersLeft = ((maxWidth + circleSize) / 2 + spacing.m)
        .clamp(0.0, maxWidth - spacing.m);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        // Clip.none lets adjuster rows extend beyond the SizedBox at large
        // text scales without being hard-clipped.
        clipBehavior: Clip.none,
        children: [
          Center(child: animWidget),
          for (var i = 0; i < state.selectedPattern.phases.length; i++)
            Positioned(
              top: centerY(state.selectedPattern.phases[i].type) -
                  rowHalfHeight,
              left: adjustersLeft,
              right: spacing.m,
              child: PhaseAdjusterRow(
                stacked: true,
                phaseType: state.selectedPattern.phases[i].type,
                seconds: state.selectedPattern.phases[i].duration.inSeconds,
                canDecrease:
                    state.selectedPattern.phases[i].duration.inSeconds >
                        PatternsBloc.minSeconds,
                canIncrease:
                    state.selectedPattern.phases[i].duration.inSeconds <
                        PatternsBloc.maxSeconds,
                onDecrease: () => context.read<PatternsBloc>().add(
                  PhaseSecondsEdited(
                    patternName: state.selectedPattern.name,
                    phaseIndex: i,
                    seconds:
                        state.selectedPattern.phases[i].duration.inSeconds - 1,
                  ),
                ),
                onIncrease: () => context.read<PatternsBloc>().add(
                  PhaseSecondsEdited(
                    patternName: state.selectedPattern.name,
                    phaseIndex: i,
                    seconds:
                        state.selectedPattern.phases[i].duration.inSeconds + 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _phaseLabel(SessionStatus status, PhaseType phase) {
    if (status == SessionStatus.completed) return 'COMPLETE';
    if (status == SessionStatus.idle || status == SessionStatus.paused) {
      return 'READY';
    }
    return PhaseAdjusterRow.labelForType(phase);
  }
}
