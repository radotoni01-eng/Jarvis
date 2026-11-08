# Jarvis – Agenten-Anleitung

Jarvis nutzt die Agenten-Sammlung **[agency-agents](https://github.com/msitarzewski/agency-agents)**
(MIT-Lizenz, siehe `LICENSE-agency-agents`), Stand Commit `b859c51` vom 05.11.2026.
Alle 283 Agenten wurden geprüft und für Claude Code (auch Cloud-Sitzungen) aufbereitet.

## 1. Struktur

```
jarvis/
├── .claude/agents/          ← AKTIVE Agenten. Claude Code lädt nur diese automatisch.
├── agents/
│   ├── library/<division>/  ← 261 cloud-kompatible Agenten (Originale, inaktiv bis aktiviert)
│   ├── restricted/<division>/ ← 22 Agenten, die in der Cloud nur eingeschränkt funktionieren
│   ├── KATALOG.md           ← Übersicht aller Agenten mit Status und Beschreibung
│   ├── catalog.json         ← dieselben Daten maschinenlesbar
│   ├── LICENSE-agency-agents
│   └── README.md            ← diese Anleitung
└── scripts/
    ├── agent.sh             ← Agenten aktivieren / deaktivieren / suchen
    └── import_agency_agents.py ← Konverter (nur für ein späteres Update nötig)
```

**Warum nicht `~/.claude/agents/` wie im Original-README?** In einer Cloud-Sitzung wird der
Container nach der Sitzung gelöscht – und damit alles im Home-Verzeichnis. `.claude/agents/`
im Projekt liegt dagegen im Git-Repository und ist in jeder neuen Sitzung sofort da.

## 2. Das aktive Kernteam (22 Agenten)

| Bereich | Agent | Wofür |
|---|---|---|
| **Jarvis-Zentrale** | `specialized-chief-of-staff` | Koordiniert, priorisiert, behält den Überblick |
| | `agents-orchestrator` | Verteilt große Aufgaben auf mehrere Agenten |
| **Schule / Abi Gesundheit & Soziales** | `research-synthesist` | Quellen auswerten, Literaturüberblick |
| | `academic-psychologist` | Psychologie, Motivation, Verhalten |
| | `academic-statistician` | Statistik, Studien richtig lesen |
| | `academic-historian` | Geschichte, historische Einordnung |
| | `academic-anthropologist` | Kultur, Gesellschaft, soziale Systeme |
| | `academic-narratologist` | Textanalyse, Erzählstrukturen (Deutsch) |
| | `healthcare-clinical-evidence-agent` | Medizinische Evidenz prüfen |
| | `language-translator` | Übersetzungen (Englisch etc.) |
| | `personal-growth-mentor` | Lernziele, Motivation, Gewohnheiten |
| | `project-management-meeting-notes-specialist` | Mitschriften strukturieren |
| | `support-executive-summary-generator` | Zusammenfassungen |
| **Jarvis entwickeln** | `engineering-senior-developer` | Code schreiben |
| | `engineering-code-reviewer` | Code prüfen |
| | `engineering-minimal-change-engineer` | Kleine, sichere Änderungen |
| | `engineering-prompt-engineer` | Prompts für Jarvis verbessern |
| | `engineering-ai-engineer` | KI-Funktionen bauen |
| | `engineering-technical-writer` | Dokumentation |
| | `engineering-git-workflow-master` | Git, Branches, Commits |
| | `testing-reality-checker` | Prüft, ob etwas wirklich fertig ist |
| | `security-ai-generated-code-auditor` | Sicherheitscheck für KI-Code |

## 3. Agenten benutzen

In einer Claude-Code-Sitzung im Jarvis-Projekt einfach schreiben:

```
Nutze den Agenten academic-psychologist und erkläre mir die Bedürfnispyramide nach Maslow mit Kritik.
```
```
Lass research-synthesist diese drei Quellen zu Pflegenotstand zusammenfassen.
```

Claude wählt passende Agenten auch selbst aus, wenn die Aufgabe zur Beschreibung passt.
Die Agenten-Prompts sind auf Englisch – sie antworten trotzdem auf Deutsch, wenn du Deutsch schreibst.

## 4. Weitere Agenten aktivieren

```bash
scripts/agent.sh search clinical          # Bibliothek durchsuchen (Agenten sind englisch: englische Begriffe!)
scripts/agent.sh info grant-writer        # Details zu einem Agenten
scripts/agent.sh activate grant-writer    # aktivieren (kopiert nach .claude/agents/)
scripts/agent.sh activate-division testing # ganze Division aktivieren
scripts/agent.sh deactivate grant-writer  # deaktivieren (Original bleibt erhalten)
scripts/agent.sh list                     # was ist aktiv?
scripts/agent.sh divisions                # alle Divisionen mit Anzahl
```

Danach:
1. Änderung committen und pushen (sonst ist sie in der nächsten Cloud-Sitzung weg).
2. **Neue Claude-Code-Sitzung starten** – Agenten werden beim Start geladen.

Ohne Skript geht es genauso: Datei aus `agents/library/<division>/` nach `.claude/agents/` kopieren.

**Tipp:** Nicht alle 283 auf einmal aktivieren. Jede Agentenbeschreibung belegt Platz im
Kontext von Claude, und bei zu vielen ähnlichen Agenten wird die automatische Auswahl ungenauer.
20–40 aktive Agenten sind ein guter Bereich.

## 5. Eingeschränkte Agenten (22)

Diese liegen in `agents/restricted/`, weil eine Cloud-Sitzung (Linux, ohne Bildschirm) die
benötigte Software oder Konten nicht hat:

- **Game-Engines** (Unity, Unreal, Roblox Studio, Godot, Blender, FMOD/Wwise): Code kann geschrieben, aber nicht im Editor getestet werden.
- **Apple-Plattformen** (visionOS, macOS/Metal, SwiftTerm): brauchen macOS und Xcode.
- **Social-Media-Automatisierung** (X/Twitter-Analyse, Carousel-Engine, Multi-Plattform-Publisher): brauchen kostenpflichtige Dienste oder API-Schlüssel.

Aktivieren geht trotzdem: `scripts/agent.sh activate unity-architect --force`.
Auf einem eigenen Rechner mit der passenden Software funktionieren sie voll.

## 6. Was am Original verändert wurde

Nur zwei Zeilen im Kopfbereich (Frontmatter) jeder Datei – der eigentliche Prompt ist unverändert:

| Feld | Original | Jarvis | Grund |
|---|---|---|---|
| `name` | `Brand Guardian` | `design-brand-guardian` | Claude Code erwartet Kleinbuchstaben + Bindestriche |
| `display_name` | – | `"Brand Guardian"` | Originalname bleibt erhalten |
| `color` | `teal`, `#1B4F72` … | `cyan`, `blue` … | Claude Code kennt nur 8 Farben |

Alle 283 Dateien wurden automatisch geprüft: Prompt-Text identisch, Frontmatter gültiges YAML.
Eine Sicherheitsprüfung fand keine versteckten Befehle oder Prompt-Injection.

## 7. Was bewusst NICHT gemacht wurde

- `scripts/install.sh` aus dem Original wurde **nicht** ausgeführt (schreibt ins Home-Verzeichnis, enthält `rm -rf`, für Cloud-Sitzungen ungeeignet).
- Die Desktop-App „Agency Agents“ und `brew` wurden nicht installiert.
- Die `integrations/`-Ordner (Cursor, Gemini, Copilot …) wurden nicht übernommen – für Claude Code nicht nötig.
- `strategy/` (Playbooks, keine Agenten) wurde nicht übernommen.

## 8. Update auf eine neue Version

```bash
git clone --depth 1 https://github.com/msitarzewski/agency-agents.git /tmp/aa
mkdir /tmp/jarvis-neu/agents -p
python3 -I scripts/import_agency_agents.py /tmp/aa /tmp/jarvis-neu
```
Dann `/tmp/jarvis-neu` mit dem Projekt vergleichen und gezielt übernehmen.
Der Konverter überschreibt nie bestehende Dateien.
