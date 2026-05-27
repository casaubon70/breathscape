# Breathscape – CLAUDE.md

## Projektübersicht

Breathscape ist eine Flutter-App zum Üben von Atemtechniken. Eine Animation
visualisiert den Lungenfüllstand durch ein vertikal gefülltes Rechteck.
Die initiale Architektur (Domain, BLoC, Animation, Integration) ist
implementiert. Diese Datei definiert die verbindlichen Standards für die
laufende Weiterentwicklung.

---

## Technologie-Stack

- **Flutter** (aktuellste stable Version)
- **State Management:** flutter_bloc – ausschließlich BLoC, keine Cubits
- **Linting:** very_good_analysis
- **Tests:** flutter_test, bloc_test, integration_test

---

## Architekturprinzipien

### Feature-first Struktur

Jedes neue Feature lebt vollständig in seinem eigenen Ordner:

```
lib/features/{feature_name}/
├── bloc/
│   ├── {feature}_bloc.dart
│   ├── {feature}_event.dart
│   └── {feature}_state.dart
├── domain/
│   └── {model}.dart
└── presentation/
    ├── {feature}_page.dart
    └── widgets/
        └── {widget}.dart
```

Shared Code (Themes, gemeinsame Widgets, Utilities) lebt in:

```
lib/core/
├── theme/
├── widgets/
└── utils/
```

### Schichtentrennung

- **Domain:** Reines Dart, keine Flutter-Abhängigkeiten.
- **BLoC:** Kennt Domain, kennt kein Widget.
- **Widgets:** Empfangen ausschließlich primitive Parameter oder
  Domain-Objekte. Kein direkter BLoC-Zugriff in Leaf-Widgets.
- **Pages:** Einzige Stelle wo `BlocProvider` und `BlocBuilder` stehen.

---

## BLoC-Standards

### Grundregeln

- Jedes Feature hat genau einen BLoC.
- States sind **immutable** – immer mit `copyWith` pattern.
- Ein einziger State-Typ pro BLoC (kein State-Sealed-Class-Splitting
  außer es gibt einen zwingenden fachlichen Grund).
- Events beschreiben **Absichten**, keine Implementierungsdetails:
  `PlayPressed`, nicht `StartAnimationTimer`.

### State-Struktur (verbindlich)

```dart
final class FeatureState extends Equatable {
  const FeatureState({
    this.status = FeatureStatus.initial,
    // weitere Felder
  });

  final FeatureStatus status;

  FeatureState copyWith({
    FeatureStatus? status,
  }) => FeatureState(
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [status];
}

enum FeatureStatus { initial, loading, success, failure }
```

### Event-Struktur (verbindlich)

```dart
sealed class FeatureEvent extends Equatable {
  const FeatureEvent();

  @override
  List<Object?> get props => [];
}

final class SomethingPressed extends FeatureEvent {
  const SomethingPressed();
}
```

### Pakete

```yaml
dependencies:
  flutter_bloc: ^9.0.0
  equatable: ^2.0.0

dev_dependencies:
  bloc_test: ^10.0.0
```

---

## Test-Standards

### Pflicht bei jedem Inkrement

Jede neue Funktionalität wird mit allen drei Test-Typen abgedeckt,
bevor das Inkrement als fertig gilt.

### Unit-Tests (Domain + BLoC)

```
test/
├── features/
│   └── {feature}/
│       ├── bloc/
│       │   └── {feature}_bloc_test.dart
│       └── domain/
│           └── {model}_test.dart
```

BLoC-Tests verwenden ausschließlich `bloc_test`:

```dart
blocTest<FeatureBloc, FeatureState>(
  'emits [loading, success] when SomethingPressed',
  build: () => FeatureBloc(),
  act: (bloc) => bloc.add(const SomethingPressed()),
  expect: () => [
    const FeatureState(status: FeatureStatus.loading),
    const FeatureState(status: FeatureStatus.success),
  ],
);
```

### Widget-Tests

```
test/
└── features/
    └── {feature}/
        └── presentation/
            └── {widget}_test.dart
```

Jedes Widget wird isoliert getestet – mit gemocktem BLoC via
`MockBloc` aus `bloc_test`. Getestet wird: initiales Rendering,
Reaktion auf State-Änderungen, korrekte Event-Emission bei
User-Interaktion.

### Integrations-Tests

```
integration_test/
└── {feature}_test.dart
```

Ein Integrations-Test pro Feature, der den vollständigen User-Flow
von der UI-Geste bis zur sichtbaren Reaktion abdeckt.

### Testregel

**Kein Inkrement wird committed, bevor alle Tests grün sind.**

---

## Code-Qualität

### Linting

`very_good_analysis` ist die einzige Linting-Abhängigkeit:

```yaml
dev_dependencies:
  very_good_analysis: ^7.0.0
```

`analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

Lint-Fehler werden **niemals** mit `// ignore` unterdrückt außer
mit expliziter Begründung im Kommentar.

### Formatierung

```bash
dart format .
```

Wird vor jedem Commit ausgeführt. Kein Code mit
Formatierungsabweichungen wird committed.

### Konstanten

`const` wird überall verwendet wo möglich –
`very_good_analysis` erzwingt dies.

### Null Safety

Explizite Typen immer. Kein implizites `dynamic`.
`!` (bang operator) ist verboten außer in begründeten Ausnahmefällen
mit erklärendem Kommentar.

---

## Commit-Standards

### Struktur

```
{type}: {kurze Beschreibung}

{optionaler Body}
```

### Typen

| Typ | Bedeutung |
|-----|-----------|
| `feat` | Neue Funktionalität |
| `fix` | Bugfix |
| `refactor` | Umstrukturierung ohne Verhaltensänderung |
| `test` | Tests hinzugefügt oder geändert |
| `chore` | Abhängigkeiten, Konfiguration, Tooling |

### Regeln

- Ein Commit = eine abgeschlossene Änderung.
- Kein Commit mit roten Tests.
- Kein Commit mit Lint-Fehlern.
- `dart format .` vor jedem Commit.

---

## Guardrails

1. **Niemals** mehr als eine Datei gleichzeitig refactoren.
2. **Niemals** funktionierende Funktionen anfassen, die nicht
   zum aktuellen Task gehören.
3. **Niemals** `// ignore` ohne Begründung.
4. **Niemals** den bang operator `!` ohne erklärendem Kommentar.
5. Bei einem Build-Fehler: **STOP** – nicht weitermachen.
6. Bei mehr als **2 erfolglosen Fix-Versuchen** auf demselben Bug:
   `git reset --hard` zum letzten Commit, anderen Ansatz wählen.

---

## Explainer Agent

Nach jedem Inkrement, vor dem Push:

```bash
claude --agent explainer
```

Der Agent erstellt ein Delta-Dokument in `docs/explainer/`.
Kein Push ohne Review des Explainer-Dokuments.
Spezifikation: `docs/explainer/EXPLAINER_AGENT_SPEC.md`
