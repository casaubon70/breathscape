---
name: project-workflow
description: Git-Workflow, Agent-Spezifikationen und Prozesse für Breathscape
metadata:
  type: project
---

Dev für Entwicklung, main für Releases; GitHub casaubon70/breathscape.

**Explainer Agent:** Nach jedem abgeschlossenen Inkrement/Milestone vor dem Push ausführen.
- Spec liegt in `.claude/agents/EXPLAINER_AGENT_SPEC.md` (nicht in `docs/explainer/`)
- Aufruf: `claude --agent explainer`
- Erstellt EXP-Dokument in `docs/explainer/`
- Kein Push ohne Review des Dokuments

**Why:** Qualitätstor vor jedem Push; dokumentiert Delta für Archiv und Nachvollziehbarkeit.
**How to apply:** Nach jedem Commit der als "fertig" gilt, proaktiv den Agent starten — nicht warten bis der User fragt.
