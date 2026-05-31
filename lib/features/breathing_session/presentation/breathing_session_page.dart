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
                    final dotsAreaHeight = CycleDotRow.rowHeight + spacing.m;
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
                                extendedInhaleInterval: dotState
                                    .selectedPattern
                                    .extendedInhaleInterval,
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

  // buildWhen for the animation BlocBuilder — fires every frame during play.
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
      prev.selectedPattern != curr.selectedPattern;

  // Builds the BreathingAnimationWidget wrapped in its SizedBox.
  // Pure function of state — no context needed.
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
        showTopCircle: state.selectedPattern.phases.any(
          (p) => p.type == PhaseType.holdIn,
        ),
        showBottomCircle: state.selectedPattern.phases.any(
          (p) => p.type == PhaseType.holdOut,
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

    // Each section has its own BlocBuilder so they rebuild independently:
    // - phase info: fires ~once per second (phaseSecondsRemaining / phase change)
    // - animation: fires every frame (fillLevel etc.)
    // - adjusters (edit mode only): fires only when pattern changes
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
          child: _editMode
              ? _buildEditStack(
                  context,
                  animHeight,
                  constraints.maxWidth,
                  spacing,
                )
              : _buildNormalStack(
                  context,
                  animHeight,
                  constraints.maxWidth,
                  animWidth,
                ),
        ),
      ],
    );
  }

  /// Normal layout: animation centred with VoiceMuteButton to the right.
  Widget _buildNormalStack(
    BuildContext context,
    double animHeight,
    double maxWidth,
    double animWidth,
  ) {
    return Stack(
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
            width: (maxWidth - animWidth) / 2,
            child: const Center(child: VoiceMuteButton()),
          ),
        ),
      ],
    );
  }

  /// Edit layout: animation centred; adjuster panel to its right.
  ///
  /// Animation and adjusters are siblings in the same Stack so they hold
  /// independent BlocBuilder subscriptions — the animation fires every frame
  /// without triggering a rebuild of the adjuster rows, which only update
  /// when the selected pattern changes.
  Widget _buildEditStack(
    BuildContext context,
    double animHeight,
    double maxWidth,
    BreathscapeSpacing spacing,
  ) {
    final circleSize = animHeight * BreathingAnimationWidget.kCircleRatio;
    const barGap = BreathingAnimationWidget.kBarGap;
    final totalHeight = circleSize * 2 + barGap * 2 + animHeight;
    final adjustersLeft = ((maxWidth + circleSize) / 2 + spacing.m).clamp(
      0.0,
      maxWidth - spacing.m,
    );

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animation: separate BlocBuilder that fires every frame.
          Center(
            child: BlocBuilder<BreathingBloc, BreathingState>(
              buildWhen: _isAnimChange,
              builder: (context, state) =>
                  _buildAnimWidget(state, animHeight, circleSize),
            ),
          ),
          // Adjusters: separate BlocBuilder that fires only on pattern change.
          Positioned.fill(
            child: BlocBuilder<BreathingBloc, BreathingState>(
              buildWhen: (prev, curr) =>
                  prev.selectedPattern != curr.selectedPattern,
              builder: (context, state) => _buildAdjusterStack(
                context,
                state,
                animHeight,
                adjustersLeft,
                spacing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the positioned adjuster rows as a Stack that fills its parent.
  Widget _buildAdjusterStack(
    BuildContext context,
    BreathingState state,
    double animHeight,
    double adjustersLeft,
    BreathscapeSpacing spacing,
  ) {
    final circleSize = animHeight * BreathingAnimationWidget.kCircleRatio;
    const barGap = BreathingAnimationWidget.kBarGap;
    final barTop = circleSize + barGap;
    const rowHalfHeight = 23.0;

    double centerY(PhaseType type) => switch (type) {
      PhaseType.holdIn => circleSize * 0.5,
      PhaseType.inhale => barTop + animHeight * 0.3,
      PhaseType.exhale => barTop + animHeight * 0.7,
      PhaseType.holdOut => barTop + animHeight + barGap + circleSize * 0.5,
      PhaseType.extendedExhale => barTop + animHeight * 0.7,
      PhaseType.extendedInhale => barTop + animHeight * 0.3,
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < state.selectedPattern.phases.length; i++)
          Positioned(
            top: centerY(state.selectedPattern.phases[i].type) - rowHalfHeight,
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
