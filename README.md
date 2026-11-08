# Jarvis
Jarvis

Persönliches KI-Assistenz-Projekt mit spezialisierten Claude-Code-Agenten.

## Agenten (`.claude/agents/`)

- `fachabi-gesundheit-tutor.md` – eigener Lern-Tutor für das Fachabi Gesundheit & Soziales
- **22 aktive Agenten** aus [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) (MIT-Lizenz, siehe `agents/LICENSE-agency-agents`)
- **283 Agenten insgesamt** in `agents/`, siehe [agents/KATALOG.md](agents/KATALOG.md)
- **Anleitung:** [agents/README.md](agents/README.md)

```bash
scripts/agent.sh list               # aktive Agenten
scripts/agent.sh search statistic   # suchen (englische Begriffe)
scripts/agent.sh activate <name>    # aktivieren, danach neue Sitzung starten
```

## OmniRoute (KI-Gateway)

- **OmniRoute-Quellcode** als Git-Submodul in `vendor/omniroute` (nur ein Verweis, wird bei Bedarf geladen)
- **46 OmniRoute-Skills** in `integrations/omniroute/skills/`, alle inaktiv, 5 davon in Quarantäne
- **Anleitung, Sicherheit, Start mit Docker:** [integrations/omniroute/README.md](integrations/omniroute/README.md)

```bash
scripts/skill.sh available                    # OmniRoute-Skills anzeigen
scripts/skill.sh activate omni-auth omni-inference
```

OmniRoute-Quelle: [cheaper-inference/OmniRoute](https://github.com/cheaper-inference/OmniRoute) (MIT).
