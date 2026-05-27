import 'package:breathscape/features/breathing_session/presentation/breathing_session_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BreathscapeApp());
}

class BreathscapeApp extends StatelessWidget {
  const BreathscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Breathscape',
      debugShowCheckedModeBanner: false,
      home: BreathingSessionPage(),
    );
  }
}
