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

  @override
  String get disclaimerTitle => 'Wichtiger Hinweis';

  @override
  String get disclaimerIntro =>
      'Breathscape ist eine App zur Unterstützung von Atemübungen für gesunde Erwachsene. Sie ersetzt keine ärztliche Beratung, Diagnose oder Behandlung.';

  @override
  String get disclaimerBullet1 =>
      'Nutze diese App nicht während du Auto fährst, Maschinen bedienst oder dich in einer anderen sicherheitskritischen Situation befindest.';

  @override
  String get disclaimerBullet2 =>
      'Atemtechniken können Schwindel oder Benommenheit verursachen. Führe Übungen immer in einer sicheren, sitzenden oder liegenden Position durch.';

  @override
  String get disclaimerBullet3 =>
      'Bei bestehenden Erkrankungen – insbesondere Herz-Kreislauf-Erkrankungen, Lungenerkrankungen, psychischen Erkrankungen oder Schwangerschaft – sprich vor der Nutzung mit deiner Ärztin oder deinem Arzt.';

  @override
  String get disclaimerBullet4 =>
      'Die Nutzung erfolgt auf eigene Verantwortung.';

  @override
  String get disclaimerAcceptButton => 'Ich stimme zu';
}
