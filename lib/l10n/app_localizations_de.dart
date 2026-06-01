// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Breathscape';

  @override
  String get phaseInhale => 'EINATMEN';

  @override
  String get phaseDeepInhale => 'TIEF EINATMEN';

  @override
  String get phaseHold => 'HALTEN';

  @override
  String get phaseExhale => 'AUSATMEN';

  @override
  String get phaseDeepExhale => 'TIEF AUSATMEN';

  @override
  String get sessionReady => 'BEREIT';

  @override
  String get sessionComplete => 'FERTIG';

  @override
  String get patternPickerTitle => 'ATEMMUSTER';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get cycleCounterLabel => 'ZYKLEN';

  @override
  String get sessionTimerLabel => 'ZEIT';

  @override
  String get voiceCuesOn => 'Sprachansagen an';

  @override
  String get voiceCuesOff => 'Sprachansagen aus';
}
