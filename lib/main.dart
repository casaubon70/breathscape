import 'package:breathscape/core/theme/bloc/theme_bloc.dart';
import 'package:breathscape/core/theme/bloc/theme_state.dart';
import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
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
            title: 'Breathscape',
            debugShowCheckedModeBanner: false,
            theme: state.theme.toThemeData(),
            home: const BreathingSessionPage(),
          );
        },
      ),
    );
  }
}
