#!/usr/bin/env bash
# Jarvis Agenten-Verwaltung
# Aktiviert/deaktiviert Agenten, indem Dateien zwischen agents/ und .claude/agents/ kopiert werden.
# Keine Downloads, keine Installation, nur Dateien innerhalb dieses Projekts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE="$ROOT/.claude/agents"
LIB="$ROOT/agents"

usage() {
  cat <<'EOF'
Verwendung: scripts/agent.sh <befehl> [argumente]

  list                    Aktive Agenten anzeigen
  search <begriff>        Bibliothek durchsuchen (Name + Beschreibung)
  info <name>             Beschreibung und Status eines Agenten
  activate <name>...      Agent(en) aktivieren
  activate-division <div> Alle cloud-kompatiblen Agenten einer Division aktivieren
  deactivate <name>...    Agent(en) deaktivieren (Original bleibt in agents/)
  divisions               Divisionen mit Anzahl anzeigen

Eingeschränkte Agenten (agents/restricted/) brauchen --force beim Aktivieren.
Nach dem Aktivieren eine neue Claude-Code-Sitzung starten, damit der Agent geladen wird.
EOF
}

find_src() { find "$LIB/library" "$LIB/restricted" -name "$1.md" -type f 2>/dev/null | head -n1; }

desc_of() { awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[ ]*/,""); print; exit}' "$1"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  list)
    echo "Aktive Agenten ($(find "$ACTIVE" -name '*.md' | wc -l)):"
    for f in "$ACTIVE"/*.md; do [ -e "$f" ] && echo "  - $(basename "$f" .md)"; done ;;
  search)
    [ $# -ge 1 ] || { usage; exit 1; }
    grep -ril --include='*.md' -- "$*" "$LIB/library" "$LIB/restricted" | while read -r f; do
      tag=""; [[ "$f" == *"/restricted/"* ]] && tag=" [eingeschränkt]"
      [ -e "$ACTIVE/$(basename "$f")" ] && tag="$tag [aktiv]"
      printf '%-50s%s\n' "$(basename "$f" .md)" "$tag"
    done ;;
  info)
    [ $# -eq 1 ] || { usage; exit 1; }
    src="$(find_src "$1")"; [ -n "$src" ] || { echo "Unbekannter Agent: $1"; exit 1; }
    echo "Name:   $1"; echo "Datei:  ${src#$ROOT/}"
    echo -n "Status: "; if [ -e "$ACTIVE/$1.md" ]; then echo aktiv; elif [[ "$src" == *"/restricted/"* ]]; then echo eingeschränkt; else echo inaktiv; fi
    echo "Info:   $(desc_of "$src")" ;;
  activate)
    force=0; names=()
    for a in "$@"; do [ "$a" = "--force" ] && force=1 || names+=("$a"); done
    [ ${#names[@]} -ge 1 ] || { usage; exit 1; }
    mkdir -p "$ACTIVE"
    for n in "${names[@]}"; do
      src="$(find_src "$n")"
      if [ -z "$src" ]; then echo "✗ $n: nicht gefunden (Tipp: scripts/agent.sh search $n)"; continue; fi
      if [ -e "$ACTIVE/$n.md" ]; then echo "• $n: bereits aktiv"; continue; fi
      if [[ "$src" == *"/restricted/"* && $force -eq 0 ]]; then
        echo "⚠ $n: eingeschränkt (siehe agents/KATALOG.md). Mit --force trotzdem aktivieren."; continue
      fi
      cp "$src" "$ACTIVE/$n.md" && echo "✓ $n aktiviert"
    done ;;
  activate-division)
    [ $# -eq 1 ] && [ -d "$LIB/library/$1" ] || { echo "Unbekannte Division. Siehe: scripts/agent.sh divisions"; exit 1; }
    mkdir -p "$ACTIVE"
    for f in "$LIB/library/$1"/*.md; do
      n="$(basename "$f")"; [ -e "$ACTIVE/$n" ] || { cp "$f" "$ACTIVE/$n"; echo "✓ ${n%.md}"; }
    done ;;
  deactivate)
    [ $# -ge 1 ] || { usage; exit 1; }
    for n in "$@"; do
      if [ ! -e "$ACTIVE/$n.md" ]; then echo "• $n: nicht aktiv"; continue; fi
      src="$(find_src "$n")"
      if [ -z "$src" ]; then echo "⚠ $n: keine Kopie in agents/ – nicht gelöscht (eigener Agent?)"; continue; fi
      if ! cmp -s "$src" "$ACTIVE/$n.md"; then
        echo "⚠ $n: aktive Version wurde verändert – nicht gelöscht. Erst sichern oder Änderung nach ${src#$ROOT/} übernehmen."; continue
      fi
      rm "$ACTIVE/$n.md" && echo "✓ $n deaktiviert"
    done ;;
  divisions)
    for d in "$LIB/library"/*/; do printf '%-22s %3s\n' "$(basename "$d")" "$(find "$d" -name '*.md' | wc -l)"; done ;;
  *) usage ;;
esac
