import 'package:breathscape/core/theme/bloc/theme_bloc.dart';
import 'package:breathscape/core/theme/bloc/theme_state.dart';
import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:breathscape/features/disclaimer/bloc/disclaimer_bloc.dart';
import 'package:breathscape/features/disclaimer/domain/disclaimer_repository.dart';
import 'package:breathscape/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BreathscapeApp());
}

class BreathscapeApp extends StatelessWidget {
  const BreathscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: state.theme.toThemeData(),
            builder: (context, child) => _OrientationWidget(child: child!),
            home: const _DisclaimerGate(),
          );
        },
      ),
    );
  }
}

class _DisclaimerGate extends StatelessWidget {
  const _DisclaimerGate();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DisclaimerBloc(repository: DisclaimerRepository())
            ..add(const DisclaimerCheckRequested()),
      child: BlocBuilder<DisclaimerBloc, DisclaimerState>(
        builder: (context, state) => switch (state.status) {
          DisclaimerStatus.accepted => const BreathingSessionPage(),
          DisclaimerStatus.notAccepted => const DisclaimerPage(),
          _ => const _LoadingScreen(),
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _OrientationWidget extends StatefulWidget {
  const _OrientationWidget({required this.child});

  final Widget child;

  @override
  State<_OrientationWidget> createState() => _OrientationWidgetState();
}

class _OrientationWidgetState extends State<_OrientationWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isIPhone =
        defaultTargetPlatform == TargetPlatform.iOS && shortestSide < 600;
    SystemChrome.setPreferredOrientations(
      isIPhone ? [DeviceOrientation.portraitUp] : DeviceOrientation.values,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
