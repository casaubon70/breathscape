// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Breathscape';

  @override
  String get phaseInhale => 'INHALE';

  @override
  String get phaseDeepInhale => 'DEEP INHALE';

  @override
  String get phaseHold => 'HOLD';

  @override
  String get phaseExhale => 'EXHALE';

  @override
  String get phaseDeepExhale => 'DEEP EXHALE';

  @override
  String get sessionReady => 'READY';

  @override
  String get sessionComplete => 'COMPLETE';

  @override
  String get patternPickerTitle => 'BREATHING PATTERN';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get cycleCounterLabel => 'CYCLES';

  @override
  String get sessionTimerLabel => 'TIME';

  @override
  String get voiceCuesOn => 'Voice cues on';

  @override
  String get voiceCuesOff => 'Voice cues off';

  @override
  String get disclaimerTitle => 'Important Notice';

  @override
  String get disclaimerIntro =>
      'Breathscape is an app to support breathing exercises for healthy adults. It is not a medical device and does not provide medical advice, diagnosis, or treatment.';

  @override
  String get disclaimerBullet1 =>
      'Do not use this app while driving, operating machinery, or in any situation where reduced alertness could cause harm.';

  @override
  String get disclaimerBullet2 =>
      'Breathing exercises may cause dizziness or lightheadedness. Always practise in a safe, seated or lying position.';

  @override
  String get disclaimerBullet3 =>
      'If you have any medical condition — including cardiovascular disease, respiratory conditions, mental health conditions, or if you are pregnant — consult a qualified healthcare professional before use.';

  @override
  String get disclaimerBullet4 => 'Use at your own risk.';

  @override
  String get disclaimerAcceptButton => 'I Agree';
}
