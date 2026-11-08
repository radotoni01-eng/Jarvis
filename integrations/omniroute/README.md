# Jarvis × OmniRoute

[OmniRoute](https://github.com/cheaper-inference/OmniRoute) (MIT, v3.8.54, Commit `2a8dc27` vom 08.11.2026)
ist ein **KI-Gateway**: ein Server, der viele KI-Anbieter (OpenAI, Gemini, Mistral, Groq, lokale Modelle …)
hinter **einer** OpenAI-kompatiblen Adresse bündelt. Er bietet automatisches Umschalten bei Limits,
Kostenkontrolle und Prompt-Kompression.

## 1. Was in Jarvis übernommen wurde – und was nicht

| Teil | Wo | Status |
|---|---|---|
| OmniRoute-Quellcode | `vendor/omniroute` | **Git-Submodul** – nur ein Verweis, wird erst bei Bedarf geladen |
| 41 OmniRoute-Skills | `skills/library/` | inaktiv, per `scripts/skill.sh activate` nutzbar |
| 5 riskante Skills | `skills/restricted/` | Quarantäne, nur mit `--force` |
| MCP-Vorlage | `mcp.example.json` | Vorlage, bewusst **nicht** aktiv |
| Lizenz | `LICENSE-omniroute` | MIT |

**Warum kein kompletter Merge?** OmniRoute hat 28.010 Dateien und 907 MB. Direkt eingemischt würde
das Jarvis unbenutzbar machen. Außerdem ist OmniRoute ein eigenständiger Server, der sowieso separat
laufen muss. Das Submodul hält die Verbindung sauber: eine Zeile, beliebig aktualisierbar.

Nicht ausgeführt wurden: `npm install`, Docker, Installations- und Setup-Skripte von OmniRoute.

## 2. Voraussetzung: OmniRoute muss irgendwo laufen

Die Skills und das MCP sind nur **Bedienungsanleitungen und Fernsteuerung** für einen laufenden
OmniRoute-Server. Ohne Server tun sie nichts.

**In einer Claude-Code-Cloud-Sitzung** ist `localhost:20128` der Cloud-Container selbst, nicht dein PC.
Möglich ist das nur, wenn du OmniRoute auf einem Server mit öffentlicher HTTPS-Adresse betreibst und
diese Adresse im Netzwerk der Cloud-Umgebung freigibst.
**Empfohlen:** OmniRoute auf dem eigenen Rechner betreiben und Claude Code lokal nutzen.

### OmniRoute lokal starten (auf deinem eigenen Rechner)

Offizieller Weg laut OmniRoute-README (Quick Start). Version fest auf die geprüfte `3.8.54`,
Port nur lokal (`127.0.0.1`) freigegeben:

```bash
docker run -d --name omniroute --restart unless-stopped --stop-timeout 40 -p 127.0.0.1:20128:20128 -v omniroute-data:/app/data diegosouzapw/omniroute:3.8.54
```

Dashboard danach: http://localhost:20128. Dort Anbieter verbinden und einen API-Schlüssel erzeugen.

**RAM beachten:** Das Image ist für Dashboard und leichten Chat ausgelegt (1 GB Heap). Wenn Claude Code
selbst über OmniRoute laufen soll, nennt die OmniRoute-Doku **8 GB Heap und mindestens 10 GB Container-RAM**:

```bash
docker run -d --name omniroute --restart unless-stopped --stop-timeout 40 --memory 10g -e OMNIROUTE_MEMORY_MB=8192 -p 127.0.0.1:20128:20128 -v omniroute-data:/app/data diegosouzapw/omniroute:3.8.54
```

Der Quellcode im Submodul wird dafür **nicht** gebraucht. Nur zum Lesen oder Selbstbauen holen:

```bash
git submodule update --init --depth 1 vendor/omniroute   # ~900 MB
```

## 3. Jarvis mit OmniRoute verbinden

### a) Skills aktivieren (Wissen, wie man OmniRoute bedient)

```bash
scripts/skill.sh available                 # alle 46 mit Status
scripts/skill.sh activate omni-auth omni-inference omni-models omni-usage-logs omni-budget
scripts/skill.sh deactivate omni-budget
```
Danach neue Claude-Code-Sitzung starten. **Empfehlung:** nur die 4–6 Skills, die du wirklich brauchst.

### b) MCP aktivieren (Claude steuert OmniRoute direkt)

```bash
cp integrations/omniroute/mcp.example.json .mcp.json
```
Oder mit dem Befehl aus der OmniRoute-Doku:
```bash
claude mcp add-server omniroute --type http --url http://localhost:20128/api/mcp/stream
```
Bewusst nicht vorinstalliert: Ein aktives `.mcp.json` ohne laufenden Server erzeugt in jeder Sitzung einen Verbindungsfehler.

### c) Claude Code selbst über OmniRoute laufen lassen (optional)

```bash
omniroute run claude --model <anbieter>/<modell>
```
Dann gehen alle Anfragen von Claude Code über OmniRoute an das gewählte Modell. Die Jarvis-Agenten
funktionieren grundsätzlich weiter. Kleinere oder kostenlose Modelle befolgen die langen Agenten-Prompts
aber spürbar schlechter.

## 4. Skills im Überblick

**API-Skills (`omni-*`)** – steuern einen laufenden Server über REST:
`omni-auth` (Start hier) · `omni-inference` (Chat, Embeddings, Bilder, Audio) · `omni-models` · `omni-providers` ·
`omni-combos-routing` · `omni-api-keys` · `omni-usage-logs` · `omni-budget` · `omni-settings` · `omni-cache` ·
`omni-compression` · `omni-context-rtk` · `omni-resilience` · `omni-mcp` · `omni-agents-a2a` · `omni-webhooks` ·
`omni-db-backups` · `omni-sync-cloud` · `omni-version-manager` · `omni-cli-tools`

**CLI-Skills (`cli-*`)** – steuern das `omniroute`-Kommandozeilenprogramm:
`cli-serve` (Start hier) · `cli-setup` · `cli-chat` · `cli-models` · `cli-providers` · `cli-keys` · `cli-routing` ·
`cli-health` · `cli-cost-usage` · `cli-compression` · `cli-contexts` · `cli-batches` · `cli-eval` · `cli-mcp` ·
`cli-a2a` · `cli-resilience` · `cli-backup-sync` · `cli-plugins-skills` · `cli-policy-audit` · `config-codex-cli`

**Sonstiges:** `ponytail` – allgemeiner Skill „einfachste funktionierende Lösung“ (YAGNI). Braucht keinen Server.

**Quarantäne (`skills/restricted/`)**:

| Skill | Warum eingeschränkt |
|---|---|
| `cli-skill-collector` | Sucht und **installiert automatisch fremde Skills von GitHub** in deine Tools (Lieferketten-Risiko) |
| `omni-github-skills` | Importiert fremde Skills aus beliebigen GitHub-Repos |
| `cli-tunnel` | Öffnet ngrok-/Cloudflare-Tunnel – macht deinen Rechner aus dem Internet erreichbar |
| `omni-tunnels` | Wie oben, über die API |
| `omni-proxies` | Proxy-Rotation für Anbieter-Anfragen |

## 5. Sicherheit & Datenschutz – bitte lesen

- **Alles läuft durch OmniRoute.** Prompts, Code und Antworten passieren den Gateway und das jeweilige
  Anbieter-Modell. Keine privaten Daten (Gesundheitsdaten, Passwörter, Schulnoten anderer) über
  kostenlose Anbieter schicken – viele nutzen Eingaben zum Training.
- **Anbieter-Bedingungen gelten.** OmniRoute markiert selbst 12 Anbieter in seinem Risiko-Katalog als
  „avoid“. Mehrere Gratis-Konten oder geteilte Abos zu stapeln, kann gegen die Bedingungen verstoßen
  und zur Sperrung führen.
- **MITM-Modul:** OmniRoute enthält einen „Traffic Inspector“, der HTTPS-Verkehr entschlüsseln kann
  (`src/mitm`, eigenes Root-Zertifikat). Nur bewusst aktivieren, Zertifikat danach wieder entfernen.
- **API-Schlüssel** nur in OmniRoutes eigener Konfiguration oder `.env` speichern, **nie** in Jarvis committen.
- Skills/MCP-Endpunkte zeigen standardmäßig auf `localhost` – OmniRoute nicht ungeschützt ins Internet stellen
  (`REQUIRE_API_KEY` aktiviert lassen).

## 6. Aktualisieren

```bash
git -C vendor/omniroute fetch --depth 1 origin main && git -C vendor/omniroute checkout FETCH_HEAD
git add vendor/omniroute && git commit -m "Update OmniRoute"
```
Skills neu übernehmen: `vendor/omniroute/skills/` mit `integrations/omniroute/skills/library/` vergleichen
(z. B. `diff -r`) und gezielt kopieren. Riskante Skills vorher wie oben prüfen.
