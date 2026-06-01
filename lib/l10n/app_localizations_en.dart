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
}
