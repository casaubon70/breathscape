# Breathscape – CLAUDE.md

## Projektübersicht

Eine Flutter-App zum Üben von Atemtechniken. Die Animation visualisiert den Füllstand der Lunge
durch ein vertikal ausgerichtetes Rechteck, dessen Füllung beim Einatmen von unten nach oben
wächst und beim Ausatmen von oben nach unten schrumpft.

---

## Architektur

### Pattern
- **BLoC** für State Management (flutter_bloc)
- **Feature-first** Ordnerstruktur
- **Vertikale Scheiben**: Jede Scheibe ist vollständig funktionsfähig, bevor die nächste beginnt

### Dateistruktur (verbindlich)

```
lib/
├── main.dart
└── features/
    └── breathing_session/
        ├── bloc/
        │   ├── breathing_bloc.dart
        │   ├── breathing_event.dart
        │   └── breathing_state.dart
        ├── domain/
        │   ├── breathing_technique.dart
        │   └── breathing_phase.dart
        └── presentation/
            ├── breathing_session_page.dart
            ├── widgets/
            │   ├── breathing_animation_widget.dart
            │   └── playback_controls.dart
            └── techniques/
                └── techniques_data.dart
```

---

## Domain-Modell

```dart
enum PhaseType { inhale, holdIn, exhale, holdOut }

class BreathingPhase {
  final PhaseType type;
  final Duration duration;
}

class BreathingTechnique {
  final String name;
  final List<BreathingPhase> phases;
}
```

Atemtechniken sind reine Datenkonfigurationen. Die Animation kennt keine Atemtechnik –
sie kennt nur `fillLevel` (0.0–1.0).

---

## BLoC

### Events
```dart
abstract class BreathingEvent {}
class PlayPressed  extends BreathingEvent {}
class PausePressed extends BreathingEvent {}
class PhaseCompleted extends BreathingEvent {} // intern vom Bloc ausgelöst
```

### State (ein einziger, unveränderlicher State)
```dart
class BreathingState {
  final SessionStatus status;   // idle | playing | paused
  final PhaseType currentPhase;
  final double fillLevel;       // 0.0 – 1.0
  final int currentCycle;
}
```

### Ticker-Strategie
Der Bloc hält einen `Ticker` und berechnet `fillLevel` frame-by-frame (Option A).
Das Widget ist vollständig passiv – es rendert nur.

---

## Kritische Schnittstellenregel

`BreathingAnimationWidget` empfängt **ausschließlich primitive Parameter**:

```dart
class BreathingAnimationWidget extends StatelessWidget {
  final double fillLevel;   // 0.0 – 1.0
  final bool isAnimating;
  // Kein Bloc, kein BuildContext-Lookup, keine Business Logic
}
```

Diese Grenze darf niemals durchbrochen werden.

---

## Implementierungsreihenfolge (Scheiben)

Jede Scheibe muss vollständig abgeschlossen sein, bevor die nächste beginnt.
Kein Scheiben-Überspringen, kein paralleles Arbeiten.

### Scheibe 1 – Domain-Modelle
**Dateien:** `breathing_phase.dart`, `breathing_technique.dart`
**Keine Flutter-Abhängigkeiten** – nur reines Dart.
**Fertig wenn:** Unit Tests grün.

### Scheibe 2 – BLoC (ohne Ticker)
**Dateien:** `breathing_event.dart`, `breathing_state.dart`, `breathing_bloc.dart`
Play/Pause-Logik implementiert. `fillLevel` ist noch hardcoded (z. B. immer `0.5`).
**Fertig wenn:** BLoC-Unit-Tests grün.

### Scheibe 3 – BreathingAnimationWidget isoliert
**Datei:** `breathing_animation_widget.dart`
Widget bekommt `fillLevel` von einem temporären Slider – kein BLoC.
**Fertig wenn:** Die Animation ist visuell korrekt in Flutter DevTools/Emulator.

### Scheibe 4 – Ticker-Logik im BLoC
`fillLevel` wird über die Zeit interpoliert, Phasen wechseln automatisch.
**Fertig wenn:** Alle Phasen der Atemtechnik laufen korrekt durch.

### Scheibe 5 – Integration
**Dateien:** `breathing_session_page.dart`, `playback_controls.dart`
BLoC + Widget + Controls werden verbunden.
**Fertig wenn:** Play/Pause funktioniert korrekt und Zyklen werden durchlaufen.

---

## Verbotene Aktionen (strikte Guardrails)

1. **Niemals** mehr als eine Datei gleichzeitig refactoren.
2. **Niemals** funktionierende Funktionen anfassen, die nicht zum aktuellen Task gehören.
3. **Niemals** die Schnittstellenregel von `BreathingAnimationWidget` brechen.
4. **Niemals** eine neue Scheibe beginnen, bevor die aktuelle abgeschlossen ist.
5. Bei einem Build-Fehler: **STOP** – nicht weitermachen, nicht weitere Änderungen vornehmen.
6. Bei mehr als **2 erfolglosen Fix-Versuchen** auf demselben Bug:
   - Änderungen rückgängig machen (`git reset --hard` zum letzten Commit)
   - Einen komplett anderen Ansatz wählen
   - Nie weiterfixxen bis der Doom Loop entsteht

---

## Commit-Strategie

Nach jeder abgeschlossenen Scheibe: sofort committen.

```
git commit -m "feat: Scheibe 1 – Domain-Modelle"
git commit -m "feat: Scheibe 2 – BLoC ohne Ticker"
git commit -m "feat: Scheibe 3 – BreathingAnimationWidget isoliert"
git commit -m "feat: Scheibe 4 – Ticker-Logik im BLoC"
git commit -m "feat: Scheibe 5 – Integration"
```

Commits sind Checkpoints. Bei Problemen wird zum letzten Checkpoint zurückgerollt –
niemals weitergefixt über einen stabilen Zustand hinaus.

---

## Test-Strategie

- **Scheibe 1 & 2:** Unit Tests mit `flutter_test` (kein Widget-Test nötig)
- **Scheibe 3:** Visueller Test im Emulator mit Slider-Steuerung
- **Scheibe 4:** BLoC-Test mit zeitgesteuerten Emit-Prüfungen
- **Scheibe 5:** Integration Test (manuell im Emulator)

Jede Scheibe baut auf grünen Tests der vorherigen auf.
