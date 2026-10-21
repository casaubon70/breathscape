import 'package:breathscape/features/breathing_session/presentation/widgets/breathing_animation_widget.dart';
import 'package:breathscape/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:breathscape/l10n/app_localizations.dart';
import 'package:breathscape/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps frames until [condition] holds or [timeout] elapses.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail('Timed out waiting for $description');
}

/// Pumps frames until [finder] matches or [timeout] elapses.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) => pumpUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  description: '$finder',
  timeout: timeout,
);

/// Localizations of the currently shown screen.
AppLocalizations l10nOf(WidgetTester tester) {
  final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  if (l10n == null) fail('AppLocalizations not available');
  return l10n;
}

/// Starts the app with an in-memory preference store seeded with
/// [preferences]. The real app's preferences on the device stay untouched.
Future<void> launchApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  await tester.pumpWidget(const BreathscapeApp());
}

/// Starts the app fresh and accepts the disclaimer, leaving the session page
/// ready.
Future<void> launchToSessionPage(WidgetTester tester) async {
  await launchApp(tester);
  await pumpUntilFound(tester, find.byType(DisclaimerPage));

  await tester.tap(find.text(l10nOf(tester).disclaimerAcceptButton));
  await pumpUntilFound(tester, find.byType(BreathingAnimationWidget));
}
